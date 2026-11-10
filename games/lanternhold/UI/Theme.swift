import SwiftUI

/// The UI's colours (DESIGN.md "Palette": parchment cards with ink, the night's indigo, fire gold, the realm's teal) and
/// the shared pieces of the HUD and the cards. Plain fills and strokes only: no materials over the running scene
/// (DESIGN.md "Tech plan", FB20808104).
enum Theme {
    static let night0 = Color(hex: 0x0E0B1E)
    static let night1 = Color(hex: 0x1C1838)
    static let night2 = Color(hex: 0x2E2A5C)
    static let moon = Color(hex: 0x8C98D0)
    static let stone = Color(hex: 0x6B6078)
    static let stoneLight = Color(hex: 0xA99CA8)
    static let parchment = Color(hex: 0xF1E3C4)
    static let parchmentDeep = Color(hex: 0xE3CFA4)
    static let ink = Color(hex: 0x2A2230)
    static let inkSoft = Color(hex: 0x2A2230).opacity(0.74)
    static let gold = Color(hex: 0xE8B84A)
    static let goldDeep = Color(hex: 0xB4832C)
    static let fireGold = Color(hex: 0xFFC65A)
    static let fireOrange = Color(hex: 0xFF8A2A)
    static let ember = Color(hex: 0xB8381A)
    static let dawnRose = Color(hex: 0xF2A6A0)
    static let teal = Color(hex: 0x2F6E8E)
    static let meadow = Color(hex: 0x6E9A4A)
    static let wood = Color(hex: 0x7A4E2E)
    static let woodDark = Color(hex: 0x4A2C18)

    /// The HUD's capsules: dark, a little see-through, a gold hairline.
    static let hudFill = night0.opacity(0.66)
    static let hudStroke = gold.opacity(0.45)

    static func serif(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    /// A colour from a 0xRRGGBB value (sRGB).
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

// MARK: - Card backgrounds

/// A parchment card: warm paper with a dark wooden edge, a thin gilt line inside and small gilt corners.
struct ParchmentBackground: View {
    var corner: CGFloat = 14

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Theme.parchment, Theme.parchmentDeep], startPoint: .top, endPoint: .bottom))
            .overlay(shape.strokeBorder(Theme.woodDark, lineWidth: 2))
            .overlay(
                RoundedRectangle(cornerRadius: max(2, corner - 5), style: .continuous)
                    .inset(by: 5)
                    .strokeBorder(Theme.goldDeep.opacity(0.55), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) { CornerGem().padding(8) }
            .overlay(alignment: .topTrailing) { CornerGem().padding(8) }
            .overlay(alignment: .bottomLeading) { CornerGem().padding(8) }
            .overlay(alignment: .bottomTrailing) { CornerGem().padding(8) }
            .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
    }
}

/// A night card (the defeat card, the pause sheet): indigo with a faint gilt edge.
struct NightBackground: View {
    var corner: CGFloat = 16

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Theme.night2, Theme.night0], startPoint: .top, endPoint: .bottom))
            .overlay(shape.strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1.5))
            .overlay(
                RoundedRectangle(cornerRadius: max(2, corner - 5), style: .continuous)
                    .inset(by: 5)
                    .strokeBorder(Theme.fireGold.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 18, x: 0, y: 8)
    }
}

/// A small gilt diamond for the cards' corners.
struct CornerGem: View {
    var body: some View {
        Rectangle()
            .fill(Theme.goldDeep.opacity(0.8))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }
}

// MARK: - Icons

/// A gold coin (DESIGN.md "Economy": a coin icon, never a currency symbol).
struct CoinIcon: View {
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Theme.fireGold, Theme.gold, Theme.goldDeep], startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(Theme.woodDark.opacity(0.6), lineWidth: max(1, size * 0.08))
            Circle()
                .inset(by: size * 0.24)
                .strokeBorder(Color.white.opacity(0.4), lineWidth: max(0.75, size * 0.07))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Two coins, one behind the other: the action button's "recruit" (soldiers are paid from the treasury).
struct CoinStack: View {
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            CoinIcon(size: size * 0.8).offset(x: -size * 0.18, y: size * 0.14)
            CoinIcon(size: size * 0.8).offset(x: size * 0.18, y: -size * 0.1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The lord's circlet (polish after round 2): the realm has a castle lord and no king, so the audience's sign is a
/// circlet, not a crown. A drawn stand-in until the art lane's icon lands: a slim band seen from the front, three
/// low points, one stone cut out of the band.
struct CircletShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: point(0.04, 0.50))
        path.addLine(to: point(0.24, 0.58))
        path.addLine(to: point(0.31, 0.36))
        path.addLine(to: point(0.38, 0.58))
        path.addLine(to: point(0.50, 0.14))
        path.addLine(to: point(0.62, 0.58))
        path.addLine(to: point(0.69, 0.36))
        path.addLine(to: point(0.76, 0.58))
        path.addLine(to: point(0.96, 0.50))
        path.addLine(to: point(0.92, 0.80))
        path.addQuadCurve(to: point(0.08, 0.80), control: point(0.50, 0.98))
        path.closeSubpath()
        // The stone.
        path.move(to: point(0.50, 0.60))
        path.addLine(to: point(0.57, 0.72))
        path.addLine(to: point(0.50, 0.84))
        path.addLine(to: point(0.43, 0.72))
        path.closeSubpath()
        return path
    }
}

/// The circlet in the foreground style, `size` points wide.
struct CircletIcon: View {
    var size: CGFloat = 34

    var body: some View {
        CircletShape()
            .fill(.foreground, style: FillStyle(eoFill: true))
            .frame(width: size, height: size * 0.72)
            .accessibilityHidden(true)
    }
}

/// The happiness face (DESIGN.md "Economy": a face with five states): joyful from 80, content from 60, calm from 30,
/// sullen from 15, angry below (unrest).
struct HappinessFace: View {
    let happiness: Int
    var size: CGFloat = 18

    enum Mood: Int, Sendable {
        case angry, sullen, calm, content, joyful
    }

    static func mood(_ happiness: Int) -> Mood {
        if happiness >= 80 { return .joyful }
        if happiness >= 60 { return .content }
        if happiness >= 30 { return .calm }
        if happiness >= 15 { return .sullen }
        return .angry
    }

    var body: some View {
        let mood = HappinessFace.mood(happiness)
        ZStack {
            Circle().fill(faceColor(mood))
            Circle().strokeBorder(Theme.woodDark.opacity(0.7), lineWidth: max(1, size * 0.07))
            HStack(spacing: size * 0.2) {
                Capsule().fill(Theme.ink).frame(width: size * 0.12, height: size * 0.17)
                Capsule().fill(Theme.ink).frame(width: size * 0.12, height: size * 0.17)
            }
            .offset(y: -size * 0.1)
            if mood == .angry {
                BrowShape()
                    .stroke(Theme.ink, style: StrokeStyle(lineWidth: max(1, size * 0.08), lineCap: .round))
                    .frame(width: size * 0.56, height: size * 0.14)
                    .offset(y: -size * 0.26)
            }
            MouthShape(curve: curve(mood))
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: max(1.1, size * 0.09), lineCap: .round))
                .frame(width: size * 0.46, height: size * 0.2)
                .offset(y: size * 0.2)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func faceColor(_ mood: Mood) -> Color {
        switch mood {
        case .joyful: return Color(hex: 0xB5D46A)
        case .content: return Color(hex: 0xE3D35E)
        case .calm: return Color(hex: 0xEDC060)
        case .sullen: return Color(hex: 0xEE9A52)
        case .angry: return Color(hex: 0xE0603A)
        }
    }

    private func curve(_ mood: Mood) -> CGFloat {
        switch mood {
        case .joyful: return 1
        case .content: return 0.55
        case .calm: return 0
        case .sullen: return -0.5
        case .angry: return -1
        }
    }
}

/// A mouth: a smile for a positive curve, a frown for a negative one, a line at 0.
struct MouthShape: Shape {
    var curve: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let ends = rect.midY - curve * rect.height * 0.5
        path.move(to: CGPoint(x: rect.minX, y: ends))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: ends),
                          control: CGPoint(x: rect.midX, y: rect.midY + curve * rect.height))
        return path
    }
}

/// Two angry brows slanting toward the nose.
struct BrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.08, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.08, y: rect.maxY))
        return path
    }
}

/// A coin and a number: a price, taxes, the treasury.
struct GoldAmount: View {
    let amount: Int
    var size: CGFloat = 15
    var color: Color = Theme.ink

    var body: some View {
        HStack(spacing: 4) {
            CoinIcon(size: size)
            Text(verbatim: "\(amount)")
                .font(Theme.rounded(size + 1, .bold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .fixedSize()
    }
}

// MARK: - Buttons

/// The main button of a card (Continue, Resume, a second chance): gilded, at least 52 pt high.
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.serif(.headline, .semibold))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .frame(minWidth: 52, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.fireGold, Theme.gold, Theme.goldDeep], startPoint: .top,
                                         endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Theme.woodDark.opacity(0.75), lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

/// A quieter button (Replay the day, Cancel, Restart chapter): an outline on the card, at least 52 pt high.
struct QuietButtonStyle: ButtonStyle {
    var onDark = false
    /// A destructive choice (restarting the chapter): ember text and border.
    var danger = false

    private var text: Color {
        if danger { return Color(hex: 0xFF8A6A) }
        return onDark ? Theme.parchment : Theme.ink
    }

    private var border: Color {
        if danger { return Color(hex: 0xD9481F).opacity(0.9) }
        return onDark ? Theme.gold.opacity(0.55) : Theme.woodDark.opacity(0.5)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.serif(.headline, .semibold))
            .foregroundStyle(text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(minWidth: 52, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(onDark ? Theme.night1.opacity(0.9) : Color.white.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(border, lineWidth: danger ? 1.6 : 1.2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// The × of a card: 44 pt.
struct CardCloseButton: View {
    let identifier: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close"))
        .accessibilityIdentifier(identifier)
    }
}

/// A ribbon banner with notched ends (the horn, the report's banners).
struct RibbonShape: Shape {
    var notch: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let depth = min(notch, rect.width / 6)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - depth, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + depth, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Scrolling only when needed

/// Sizes its one child to the child's ideal height, but never taller than offered: a ScrollView inside reports its
/// content's height as its ideal, so a card hugs its content and scrolls only when the screen is too short (Dynamic
/// Type, German). `ViewThatFits` took the whole height offered and centred short content in a tall card.
struct HuggingHeight: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let ideal = child.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let height = min(ideal.height, proposal.height ?? ideal.height)
        return CGSize(width: proposal.width ?? ideal.width, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading,
                              proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
    }
}

/// A card's body: as tall as its content, scrolling (with a flash of the indicator) only when it does not fit.
struct CardScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HuggingHeight {
            ScrollView(.vertical, showsIndicators: true) {
                content()
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicatorsFlash(onAppear: true)
        }
    }
}
