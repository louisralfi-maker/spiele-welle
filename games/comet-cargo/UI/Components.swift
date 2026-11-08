import SwiftUI

/// The coin: a mustard disc with a rim and a star. Never a currency symbol.
struct CoinIcon: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { context, canvasSize in
            CoinShape.draw(in: context, center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2), radius: canvasSize.width / 2)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Coin drawing for any Canvas (a plain enum, so the flight scene can call it off the main actor).
enum CoinShape {
    static func draw(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: outer), with: .color(Palette.mustard))
        let inner = outer.insetBy(dx: radius * 0.22, dy: radius * 0.22)
        context.stroke(Path(ellipseIn: inner), with: .color(Palette.ink.opacity(0.35)), lineWidth: max(1, radius * 0.12))
        var star = Path()
        let points = 5
        let starRadius = radius * 0.42
        for index in 0..<(points * 2) {
            let angle = Double(index) * Double.pi / Double(points) - Double.pi / 2
            let r = index % 2 == 0 ? starRadius : starRadius * 0.45
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            if index == 0 { star.move(to: CGPoint(x: x, y: y)) } else { star.addLine(to: CGPoint(x: x, y: y)) }
        }
        star.closeSubpath()
        context.fill(star, with: .color(Palette.ink.opacity(0.45)))
    }
}

/// A number of coins with the coin icon.
struct CoinAmount: View {
    var value: Int
    var size: CGFloat = 18
    var color: Color = Palette.ink

    var body: some View {
        HStack(spacing: 5) {
            CoinIcon(size: size)
            Text(value, format: .number)
                .font(.rounded(size, .heavy).monospacedDigit())
                .foregroundStyle(color)
        }
    }
}

/// A small satellite: a gold body with two teal solar panels. `unfold` 0…1 opens the panels.
enum SatelliteShape {
    static func draw(in context: GraphicsContext, at center: CGPoint, size: CGFloat, unfold: Double = 1, dim: Bool = false, angle: Double = 0) {
        var ctx = context
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: .radians(angle))
        if dim { ctx.opacity = 0.45 }
        let body = CGRect(x: -size * 0.22, y: -size * 0.22, width: size * 0.44, height: size * 0.44)
        let open = CGFloat(min(1, max(0, unfold)))
        let panelWidth = size * 0.42 * open
        let panelHeight = size * 0.26
        if panelWidth > 0.5 {
            let left = CGRect(x: body.minX - panelWidth - size * 0.04, y: -panelHeight / 2, width: panelWidth, height: panelHeight)
            let right = CGRect(x: body.maxX + size * 0.04, y: -panelHeight / 2, width: panelWidth, height: panelHeight)
            var arm = Path()
            arm.move(to: CGPoint(x: left.maxX, y: 0))
            arm.addLine(to: CGPoint(x: right.minX, y: 0))
            ctx.stroke(arm, with: .color(Palette.paper), lineWidth: max(1, size * 0.05))
            for panel in [left, right] {
                ctx.fill(Path(roundedRect: panel, cornerRadius: size * 0.04), with: .color(Palette.deepTeal))
                ctx.stroke(Path(roundedRect: panel, cornerRadius: size * 0.04), with: .color(Palette.skyTeal), lineWidth: max(0.8, size * 0.035))
            }
        }
        ctx.fill(Path(roundedRect: body, cornerRadius: size * 0.1), with: .color(Palette.mustard))
        ctx.stroke(Path(roundedRect: body, cornerRadius: size * 0.1), with: .color(Palette.ink.opacity(0.5)), lineWidth: max(0.8, size * 0.04))
        var dish = Path()
        dish.move(to: CGPoint(x: 0, y: body.minY))
        dish.addLine(to: CGPoint(x: 0, y: body.minY - size * 0.16))
        ctx.stroke(dish, with: .color(Palette.paper), lineWidth: max(1, size * 0.05))
        let tip = CGRect(x: -size * 0.06, y: body.minY - size * 0.24, width: size * 0.12, height: size * 0.12)
        ctx.fill(Path(ellipseIn: tip), with: .color(Palette.coral))
    }
}

struct SatelliteIcon: View {
    var size: CGFloat = 40

    var body: some View {
        Canvas { context, canvasSize in
            SatelliteShape.draw(in: context, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2 + size * 0.06), size: canvasSize.width)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A light paper grain over a whole screen (seeded dots, drawn once).
struct PaperGrain: View, Equatable {
    var opacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double(seed >> 11) / Double(1 << 53)
            }
            let count = Int(size.width * size.height / 150)
            for _ in 0..<count {
                let x = CGFloat(next()) * size.width
                let y = CGFloat(next()) * size.height
                let dark = next() < 0.5
                let r = CGFloat(0.4 + next() * 0.8)
                let color = dark ? Palette.ink : Palette.paper
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(color.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The big coral pill button.
struct PillButtonStyle: ButtonStyle {
    var fill: Color = Palette.coral
    var text: Color = Palette.paper

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(24, .heavy))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                Capsule().fill(fill)
                    .shadow(color: Palette.ink.opacity(0.25), radius: 0, x: 0, y: configuration.isPressed ? 1 : 4)
            )
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// A number that rolls up from 0 to `value` over `duration` (instant under Reduce Motion).
struct RollingNumber: View {
    var value: Int
    var duration: Double = 1.0
    var size: CGFloat = 44
    var color: Color = Palette.ink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    init(value: Int, duration: Double = 1.0, size: CGFloat = 44, color: Color = Palette.ink) {
        self.value = value
        self.duration = duration
        self.size = size
        self.color = color
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let shown = displayed(at: timeline.date)
            HStack(spacing: 8) {
                CoinIcon(size: size * 0.8)
                Text(shown, format: .number)
                    .font(.rounded(size, .black).monospacedDigit())
                    .foregroundStyle(color)
            }
        }
        .onAppear { start = Date() }
    }

    private func displayed(at date: Date) -> Int {
        if reduceMotion { return value }
        let t = min(1, max(0, date.timeIntervalSince(start) / duration))
        let eased = 1 - pow(1 - t, 3)
        return Int((Double(value) * eased).rounded())
    }
}

extension DropRating {
    var title: String {
        switch self {
        case .perfect: return String(localized: "Perfect")
        case .great: return String(localized: "Great")
        case .good: return String(localized: "Good")
        case .early: return String(localized: "Early")
        case .late: return String(localized: "Late")
        }
    }

    var tint: Color {
        switch self {
        case .perfect: return Palette.mustard
        case .great: return Palette.skyTeal
        case .good: return Palette.paper
        case .early, .late: return Palette.coral
        }
    }
}

extension ReleaseRating {
    var title: String {
        switch self {
        case .perfect: return String(localized: "Perfect")
        case .great: return String(localized: "Great")
        case .good: return String(localized: "Good")
        case .lost: return String(localized: "Lost")
        }
    }

    var tint: Color {
        switch self {
        case .perfect: return Palette.mustard
        case .great: return Palette.skyTeal
        case .good: return Palette.paper
        case .lost: return Palette.coral
        }
    }
}

extension UpgradeTrack {
    var title: String {
        switch self {
        case .engines: return String(localized: "Engines")
        case .tanks: return String(localized: "Tanks")
        case .stages: return String(localized: "Stages")
        case .cargo: return String(localized: "Cargo bay")
        case .guidance: return String(localized: "Guidance")
        }
    }

    var symbol: String {
        switch self {
        case .engines: return "flame.fill"
        case .tanks: return "fuelpump.fill"
        case .stages: return "square.stack.3d.up.fill"
        case .cargo: return "shippingbox.fill"
        case .guidance: return "scope"
        }
    }

    /// What the current level gives, in a few words.
    func effect(at level: Int) -> String {
        switch self {
        case .engines:
            let share = pow(RocketConfig.engineStep, Double(level)) - 1
            return String(localized: "Thrust +\(UpgradeTrack.percent(share))")
        case .tanks:
            let share = pow(RocketConfig.tankStep, Double(level)) - 1
            return String(localized: "Fuel +\(UpgradeTrack.percent(share))")
        case .stages:
            return String(localized: "\(level) stages")
        case .cargo:
            return String(localized: "\(level) satellites")
        case .guidance:
            return String(localized: "Timing windows +\(UpgradeTrack.percent(Double(level) * 0.1))")
        }
    }

    /// "9 %" or "9%" as the locale writes it.
    static func percent(_ share: Double) -> String {
        share.formatted(.percent.precision(.fractionLength(0)))
    }
}
