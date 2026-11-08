import SwiftUI

/// Home: coins and settings, the ring network with the best altitude and the next ring, five upgrade rows and the big
/// Launch button. The Launch bar sits below the scroll view, never on top of it, so no row can hide behind it; on the
/// 874 pt iPhone 17 Pro all five rows fit above it, smaller screens scroll.
struct HangarView: View {
    let model: GameModel

    var body: some View {
        let save = model.save
        ZStack {
            Palette.cream.ignoresSafeArea()
            PaperGrain(opacity: 0.05).equatable().ignoresSafeArea()
            VStack(spacing: 0) {
                topBar(save)
                ScrollView {
                    VStack(spacing: 12) {
                        networkCard(save)
                        VStack(spacing: 7) {
                            ForEach(UpgradeTrack.allCases) { track in
                                UpgradeRow(track: track, save: save) { model.buy(track) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                launchBar
            }
        }
    }

    private var launchBar: some View {
        Button {
            model.launch()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                Text("Launch")
            }
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(Text("Launch"))
        .accessibilityIdentifier("hangar-launch")
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            Palette.cream
                .overlay(alignment: .top) { Rectangle().fill(Palette.ink.opacity(0.08)).frame(height: 1) }
                .ignoresSafeArea()
        )
    }

    private func topBar(_ save: SaveGame) -> some View {
        HStack {
            HStack(spacing: 6) {
                CoinIcon(size: 24)
                Text(save.coins, format: .number)
                    .font(.rounded(26, .black).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .accessibilityLabel(Text("\(save.coins) coins"))
                    .accessibilityIdentifier("hangar-coins")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.paper))
            Spacer()
            Button {
                Feedback.shared.play(.button)
                model.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Palette.deepTeal)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Palette.paper))
            }
            .accessibilityLabel(Text("Settings"))
            .accessibilityIdentifier("settings-open")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func networkCard(_ save: SaveGame) -> some View {
        VStack(spacing: 4) {
            NetworkView(deliveries: save.ringDeliveries, bestApex: save.bestApex, still: model.args.still)
                .frame(height: 200)
            HStack {
                Text("Best: \(Int(save.bestApex.rounded())) km")
                    .font(.rounded(17, .heavy).monospacedDigit())
                    .foregroundStyle(Palette.paper)
                    .accessibilityIdentifier("hangar-best")
                Spacer()
                Text("\(save.completedRings)/15 rings")
                    .font(.rounded(15, .bold).monospacedDigit())
                    .foregroundStyle(Palette.mustard)
            }
            .padding(.horizontal, 16)
            nextRing(save)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [Palette.navy, Palette.night], startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Palette.ink.opacity(0.25), lineWidth: 1))
    }

    /// The goal of the next flights: the lowest ring above the best apex, with its altitude and pay.
    @ViewBuilder
    private func nextRing(_ save: SaveGame) -> some View {
        if let ring = NetworkDrawing.nextRing(bestApex: save.bestApex) {
            HStack(spacing: 5) {
                Text("Next: Ring \(ring + 1) · \(Int(Rings.altitudes[ring])) km")
                    .font(.rounded(14, .bold).monospacedDigit())
                    .foregroundStyle(Palette.paper.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                CoinIcon(size: 14)
                Text(verbatim: "\(Rings.basePay(ring))")
                    .font(.rounded(14, .heavy).monospacedDigit())
                    .foregroundStyle(Palette.mustard)
            }
            .accessibilityElement(children: .combine)
        } else {
            Color.clear.frame(height: 0)
        }
    }
}

struct UpgradeRow: View {
    let track: UpgradeTrack
    let save: SaveGame
    let onBuy: () -> Void

    var body: some View {
        let level = save.levels[track]
        let price = Economy.price(track, level: level)
        let affordable = price.map { save.coins >= $0 } ?? false
        HStack(spacing: 12) {
            Image(systemName: track.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Palette.paper)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Palette.deepTeal))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.rounded(17, .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(track.effect(at: level))
                    .font(.rounded(13, .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                LevelPips(filled: level - track.minLevel, total: track.steps)
            }
            Spacer(minLength: 4)
            Button(action: onBuy) {
                Group {
                    if let price {
                        HStack(spacing: 4) {
                            CoinIcon(size: 15)
                            Text(price, format: .number)
                                .font(.rounded(16, .heavy).monospacedDigit())
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    } else {
                        Text("Max")
                            .font(.rounded(16, .heavy))
                    }
                }
                .foregroundStyle(affordable ? Palette.paper : Palette.ink.opacity(0.45))
                .frame(minWidth: 92, minHeight: 44)
                .padding(.horizontal, 6)
                .background(Capsule().fill(affordable ? Palette.coral : Palette.ink.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
            .accessibilityLabel(buyLabel(price))
            .accessibilityIdentifier("upgrade-\(track.rawValue)-buy")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.paper))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.ink.opacity(0.08), lineWidth: 1))
    }

    private func buyLabel(_ price: Int?) -> Text {
        if let price {
            return Text("Buy \(track.title) for \(price) coins")
        }
        return Text("\(track.title): maximum")
    }
}

struct LevelPips: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? Palette.mustard : Palette.ink.opacity(0.12))
                    .frame(width: total > 6 ? 9 : 16, height: 6)
            }
        }
        .accessibilityHidden(true)
    }
}
