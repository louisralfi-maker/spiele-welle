import CoreText
import SwiftUI
import UIKit

/// The interface in the realm map's style (docs/UI-look.md; DESIGN.md "The interface in the map's style"): parchment
/// and ink, IM Fell English, wax-red rubrics, gold, House Lantern's teal, on the dark of a writing desk. The colours,
/// the type and the shared pieces of the HUD and the cards. Plain fills and strokes only: no materials over the
/// running scene (DESIGN.md "Tech plan", FB20808104).
enum Theme {
    // The map's palette (docs/karte.html).
    /// The writing desk: the dark under the papers (the pause sheet, the defeat card, the veil).
    static let desk = Color(hex: 0x1D1712)
    static let desk2 = Color(hex: 0x2A2119)
    /// Writing on the desk.
    static let bone = Color(hex: 0xE4D6B4)
    static let boneDim = Color(hex: 0xB3A27F)
    /// A sheet of parchment, from its light corner to its deep one.
    static let parchment = Color(hex: 0xECDCB1)
    static let parchmentMid = Color(hex: 0xDCC690)
    static let parchmentDeep = Color(hex: 0xCDB47C)
    /// The lighter slip of a plaque on the sheet.
    static let plaque = Color(hex: 0xF4E9CB)
    static let ink = Color(hex: 0x38281A)
    static let inkSoft = Color(hex: 0x6A5236)
    /// The ink rules of a frame.
    static let rule = Color(hex: 0x5D4526)
    /// House Lantern's teal: Odile's hand, what is chosen, what opens.
    static let teal = Color(hex: 0x1F5C5E)
    static let gold = Color(hex: 0xD19A2C)
    static let goldHi = Color(hex: 0xF4C85A)
    /// Wax red: rubrics, seals, warnings.
    static let rubric = Color(hex: 0x8C3423)
    static let rubricHi = Color(hex: 0xB9503A)
    static let rubricDeep = Color(hex: 0x63200F)
    /// The words and signs pressed into wax.
    static let sealWords = Color(hex: 0xF6E8C6)
    /// A warning written on the desk (the rubric is too dark there).
    static let rubricOnDesk = Color(hex: 0xE58A6E)

    // Fire and land for the strip of map and the banners.
    static let fireOrange = Color(hex: 0xE8822A)
    static let meadow = Color(hex: 0x8F9A58)
    static let stone = Color(hex: 0x9C8E78)

    // Names kept from the first look, on the map's palette (the other lanes' code still says them).
    static let night0 = desk
    static let night1 = desk2
    static let night2 = Color(hex: 0x3A2E22)
    static let moon = boneDim
    static let stoneLight = plaque
    static let goldDeep = Color(hex: 0x8A621A)
    static let fireGold = goldHi
    static let ember = rubric
    static let dawnRose = Color(hex: 0xD9967E)
    static let wood = Color(hex: 0x7A4E2E)
    static let woodDark = rule
    static let hudFill = desk.opacity(0.8)
    static let hudStroke = boneDim.opacity(0.6)

    // MARK: Type

    private static let fellRoman = "IM_FELL_English_Roman"
    private static let fellItalic = "IM_FELL_English_Italic"
    private static let fellCaps = "IM_FELL_English_SC"
    private static let fellFiles = ["IMFeENrm28P", "IMFeENit28P", "IMFeENsc28P"]
    private static let figureFace = "Baskerville-SemiBold"

    /// Which faces write the words: IM Fell English (bundled, SIL OFL; Resources/Fonts) for the Latin languages,
    /// Hiragino Mincho for Japanese, the system's serif for Simplified Chinese and wherever a face is missing.
    enum Script: Sendable {
        case fell, mincho, system
    }

    static let script: Script = {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        if language.hasPrefix("ja") {
            return UIFont(name: "HiraMinProN-W3", size: 12) == nil ? Script.system : Script.mincho
        }
        if language.hasPrefix("zh") { return Script.system }
        // The Info.plist registers the three files (UIAppFonts); this is the second lock on the same door.
        if UIFont(name: Theme.fellRoman, size: 12) == nil {
            for file in Theme.fellFiles {
                if let url = Bundle.main.url(forResource: file, withExtension: "ttf") {
                    _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
        let ready = [Theme.fellRoman, Theme.fellItalic, Theme.fellCaps].allSatisfy { UIFont(name: $0, size: 12) != nil }
        return ready ? Script.fell : Script.system
    }()

    private static let hasFigureFace = UIFont(name: Theme.figureFace, size: 12) != nil

    /// IM Fell's point size for a text style: a point over the system's, since its x-height is small. Its lines are
    /// as tall as the system's were, so the cards keep their heights.
    private static func points(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 35
        case .title: return 29
        case .title2: return 23
        case .title3: return 21
        case .headline: return 18
        case .body: return 18
        case .callout: return 17
        case .subheadline: return 16
        case .footnote: return 14
        case .caption: return 13
        case .caption2: return 12
        default: return 18
        }
    }

    /// The words of the interface, scaling with Dynamic Type. IM Fell has no bold: `.bold` and heavier are its small
    /// capitals (headings, names), everything lighter its roman.
    static func serif(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        let strong = weight == .bold || weight == .heavy || weight == .black
        switch script {
        case .fell:
            return .custom(strong ? fellCaps : fellRoman, size: points(style), relativeTo: style)
        case .mincho:
            return .custom(weight == .regular ? "HiraMinProN-W3" : "HiraMinProN-W6", size: points(style) - 1,
                           relativeTo: style)
        case .system:
            return .system(style, design: .serif, weight: weight)
        }
    }

    /// Small capitals: headings, names, the words on a seal.
    static func caps(_ style: Font.TextStyle) -> Font {
        serif(style, .bold)
    }

    /// The italic: asides, what somebody says, a hand writing.
    static func italic(_ style: Font.TextStyle) -> Font {
        switch script {
        case .fell: return .custom(fellItalic, size: points(style), relativeTo: style)
        case .mincho: return serif(style)
        case .system: return serif(style).italic()
        }
    }

    /// The three cuts of the house's type.
    enum Face: Sendable {
        case roman, italic, caps
    }

    /// The house's type at a fixed size, for the HUD, whose room beside the strip is fixed.
    static func hand(_ size: CGFloat, _ face: Face = .roman) -> Font {
        switch script {
        case .fell:
            let name: String
            switch face {
            case .roman: name = fellRoman
            case .italic: name = fellItalic
            case .caps: name = fellCaps
            }
            return .custom(name, fixedSize: size)
        case .mincho:
            return .custom(face == .caps ? "HiraMinProN-W6" : "HiraMinProN-W3", fixedSize: size - 1)
        case .system:
            let font = Font.system(size: size - 1, weight: face == .caps ? .bold : .regular, design: .serif)
            return face == .italic ? font.italic() : font
        }
    }

    /// The ledger's figures at a fixed size: IM Fell's old-style 1 reads as an I, so numbers are set in Baskerville's
    /// lining figures (on every iPhone), which a glance tells apart.
    static func figures(_ size: CGFloat) -> Font {
        hasFigureFace ? .custom(figureFace, fixedSize: size) : .system(size: size, weight: .semibold, design: .serif)
    }

    /// The ledger's figures beside words of a text style.
    static func figures(relativeTo style: Font.TextStyle) -> Font {
        if hasFigureFace {
            return .custom(figureFace, size: (points(style) * 0.94).rounded(), relativeTo: style)
        }
        return .system(style, design: .serif, weight: .semibold)
    }

    /// The first look's name for the figures (the other lanes' code still says it).
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        figures(size)
    }

    /// A line of words whose digits stand in the ledger's figures ("Day 1" must not read "Day I").
    static func figured(_ string: String, _ style: Font.TextStyle) -> AttributedString {
        figured(string, in: figures(relativeTo: style))
    }

    /// The same at a fixed size (the HUD).
    static func figured(_ string: String, size: CGFloat) -> AttributedString {
        figured(string, in: figures(size))
    }

    private static func figured(_ string: String, in figureFont: Font) -> AttributedString {
        guard script == .fell, string.contains(where: { $0.isASCII && $0.isNumber }) else {
            return AttributedString(string)
        }
        var result = AttributedString()
        var piece = ""
        var pieceIsDigits = false
        for character in string {
            let digit = character.isASCII && character.isNumber
            if digit != pieceIsDigits, !piece.isEmpty {
                var part = AttributedString(piece)
                if pieceIsDigits { part.swiftUI.font = figureFont }
                result.append(part)
                piece = ""
            }
            pieceIsDigits = digit
            piece.append(character)
        }
        if !piece.isEmpty {
            var part = AttributedString(piece)
            if pieceIsDigits { part.swiftUI.font = figureFont }
            result.append(part)
        }
        return result
    }
}

extension Text {
    /// Words in the house's type with their digits in the ledger's figures (`Theme.figured`); the font of the words
    /// comes from `.font` as usual.
    init(inked string: String, _ style: Font.TextStyle) {
        self.init(Theme.figured(string, style))
    }

    /// The same beside words of a fixed size (the HUD).
    init(inked string: String, size: CGFloat) {
        self.init(Theme.figured(string, size: size))
    }
}

extension Color {
    /// A colour from a 0xRRGGBB value (sRGB).
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

// MARK: - Frames

/// The inner rule of a frame, its four lines running a little past each other at the corners, as on the map's border.
struct CrossedRule: Shape {
    var inset: CGFloat = 5
    var reach: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inner = rect.insetBy(dx: inset, dy: inset)
        guard inner.width > 0, inner.height > 0 else { return path }
        path.move(to: CGPoint(x: inner.minX - reach, y: inner.minY))
        path.addLine(to: CGPoint(x: inner.maxX + reach, y: inner.minY))
        path.move(to: CGPoint(x: inner.minX - reach, y: inner.maxY))
        path.addLine(to: CGPoint(x: inner.maxX + reach, y: inner.maxY))
        path.move(to: CGPoint(x: inner.minX, y: inner.minY - reach))
        path.addLine(to: CGPoint(x: inner.minX, y: inner.maxY + reach))
        path.move(to: CGPoint(x: inner.maxX, y: inner.minY - reach))
        path.addLine(to: CGPoint(x: inner.maxX, y: inner.maxY + reach))
        return path
    }
}

/// A sheet of parchment (a letter, a page of the chronicle, of the family book, of the builders' ledger): the map's
/// card. Warm paper, darker toward one corner, nearly square corners, an ink rule at the edge and a second one inside
/// whose lines cross at the corners.
struct ParchmentBackground: View {
    /// Kept from the first look's rounded cards; the sheets are cut square (2 pt) whatever is asked.
    var corner: CGFloat = 2
    /// A small slip (Odile's note, a caption) has no room for the inner rule.
    var ruled = true

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
        shape
            .fill(LinearGradient(stops: [.init(color: Theme.parchment, location: 0),
                                         .init(color: Theme.parchmentMid, location: 0.6),
                                         .init(color: Theme.parchmentDeep, location: 1)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(shape.strokeBorder(Theme.rule, lineWidth: 1))
            .overlay {
                if ruled {
                    CrossedRule(inset: 5, reach: 3).stroke(Theme.rule.opacity(0.85), lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

/// A slip of parchment over the scene (the HUD's ledger, a caption, a word from the court, Odile's note): the sheet's
/// paper inside one ink rule, cut square.
struct SlipBackground: View {
    /// Odile's hand: the rule in House Lantern's teal.
    var teal = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Theme.parchment, Theme.parchmentMid], startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay(shape.strokeBorder(teal ? Theme.teal : Theme.rule, lineWidth: teal ? 1.5 : 1))
            .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 2)
    }
}

/// The desk under the papers (the pause sheet, the defeat card): dark wood, a bone line at the edge and a faint gold
/// rule inside.
struct NightBackground: View {
    var corner: CGFloat = 2

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Theme.desk2, Theme.desk], startPoint: .top, endPoint: .bottom))
            .overlay(shape.strokeBorder(Theme.boneDim.opacity(0.75), lineWidth: 1))
            .overlay(CrossedRule(inset: 5, reach: 3).stroke(Theme.gold.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
    }
}

/// An inked plaque: a lighter slip with an ink rule and a hairline inside it. What can be chosen stands on one (a
/// petition's choices, the rows of a card); House Lantern's teal frames the one that is marked (Odile's choice, the
/// tax in force).
struct PlaqueBackground: View {
    var enabled = true
    var marked = false
    var pressed = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
        shape
            .fill(pressed ? Theme.parchmentDeep.opacity(0.9) : Theme.plaque.opacity(enabled ? 0.82 : 0.3))
            .overlay(shape.strokeBorder(marked ? Theme.teal : Theme.rule.opacity(enabled ? 0.9 : 0.4),
                                        lineWidth: marked ? 2 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .inset(by: 3)
                    .strokeBorder(Theme.rule.opacity(enabled ? 0.32 : 0.16), lineWidth: 1)
            )
    }
}

/// A thin ink rule across a sheet.
struct InkRule: View {
    var color: Color = Theme.rule.opacity(0.6)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// A rule with a small lozenge at its middle, as under the map's title: it closes a heading.
struct FlourishRule: View {
    var color: Color = Theme.rule.opacity(0.7)
    var gem: Color = Theme.rubric

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(color).frame(height: 1)
            Rectangle().fill(gem).frame(width: 5, height: 5).rotationEffect(.degrees(45))
            Rectangle().fill(color).frame(height: 1)
        }
        .frame(height: 9)
        .accessibilityHidden(true)
    }
}

/// A ledger's leader: a row of ink dots from an entry to its figure. It takes the room the words leave (a lower
/// layout priority, as a Spacer has), so a long entry still wraps as late as it did.
struct Leader: View {
    var body: some View {
        LeaderLine()
            .stroke(Theme.rule.opacity(0.6), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [0.1, 4.6]))
            .frame(minWidth: 6, maxWidth: .infinity)
            .frame(height: 3)
            .layoutPriority(-1)
            .accessibilityHidden(true)
    }
}

/// The leader's line through the middle of its frame.
struct LeaderLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.midY))
        return path
    }
}

/// A wax seal: a disc of wax red, lit from the upper left, with a pressed ring (the pause button, the action button).
struct WaxSeal: View {
    /// The wax has set grey: what the seal offers cannot be done now.
    var spent = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: spent ? [Color(hex: 0x6B5F52), Color(hex: 0x4A4037), Color(hex: 0x2E2720)]
                                                       : [Theme.rubricHi, Theme.rubric, Theme.rubricDeep],
                                         center: UnitPoint(x: 0.36, y: 0.3), startRadius: 0, endRadius: side * 0.62))
                Circle()
                    .strokeBorder(Color.black.opacity(0.45), lineWidth: max(1, side * 0.03))
                Circle()
                    .inset(by: side * 0.1)
                    .strokeBorder(Color.black.opacity(0.22), lineWidth: max(1, side * 0.025))
                Circle()
                    .inset(by: side * 0.1 + max(1, side * 0.025))
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }
}

/// A small gilt diamond (kept from the first look for the lanes that still place one).
struct CornerGem: View {
    var body: some View {
        Rectangle()
            .fill(Theme.goldDeep.opacity(0.8))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }
}

// MARK: - Icons, drawn in the same ink

/// A gold coin (DESIGN.md "Economy": a coin icon, never a currency symbol): gold leaf inside an ink line.
struct CoinIcon: View {
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Theme.goldHi, Theme.gold], startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(Theme.ink, lineWidth: max(1, size * 0.09))
            Circle()
                .inset(by: size * 0.27)
                .strokeBorder(Theme.ink.opacity(0.5), lineWidth: max(0.75, size * 0.06))
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

/// Two people, head and shoulders, one a step behind the other.
struct PeopleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        func person(centre: CGFloat, head: CGFloat, top: CGFloat, half: CGFloat, foot: CGFloat) {
            let cx = rect.minX + w * centre
            path.addEllipse(in: CGRect(x: cx - w * head / 2, y: rect.minY + h * top, width: w * head, height: w * head))
            let shoulders = rect.minY + h * top + w * head + h * 0.05
            let base = rect.minY + h * foot
            path.move(to: CGPoint(x: cx - w * half, y: base))
            path.addCurve(to: CGPoint(x: cx + w * half, y: base),
                          control1: CGPoint(x: cx - w * half, y: shoulders - (base - shoulders) * 0.35),
                          control2: CGPoint(x: cx + w * half, y: shoulders - (base - shoulders) * 0.35))
            path.closeSubpath()
        }
        person(centre: 0.7, head: 0.3, top: 0.08, half: 0.26, foot: 0.92)
        person(centre: 0.34, head: 0.36, top: 0.0, half: 0.32, foot: 1.0)
        return path
    }
}

/// The people of the valley as an icon.
struct PeopleIcon: View {
    var size: CGFloat = 16
    var color: Color = Theme.ink

    var body: some View {
        PeopleShape()
            .fill(color)
            .frame(width: size, height: size * 0.86)
            .accessibilityHidden(true)
    }
}

/// The happiness face (DESIGN.md "Economy": a face with five states): joyful from 80, content from 60, calm from 30,
/// sullen from 15, angry below (unrest). A wash of colour inside an ink line, the features in ink.
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
            Circle().strokeBorder(Theme.ink, lineWidth: max(1, size * 0.08))
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
        case .joyful: return Color(hex: 0xB4C26A)
        case .content: return Color(hex: 0xE2CC66)
        case .calm: return Color(hex: 0xE6BC62)
        case .sullen: return Color(hex: 0xE09A55)
        case .angry: return Color(hex: 0xD0603C)
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
                .font(Theme.figures(size + 2))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .fixedSize()
    }
}

// MARK: - Buttons

/// The main button of a card (Continue, Resume, Begin, a second chance): a plaque of wax red with its words pressed in
/// small capitals, at least 52 pt high. (The name is the first look's; every card says it.)
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        return configuration.label
            .font(Theme.caps(.headline))
            .foregroundStyle(Theme.sealWords)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .frame(minWidth: 52, minHeight: 52)
            .background(
                shape.fill(LinearGradient(colors: [Theme.rubricHi, Theme.rubric, Theme.rubricDeep],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(shape.strokeBorder(Color(hex: 0x4A160B), lineWidth: 1))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .inset(by: 3)
                    .strokeBorder(Theme.sealWords.opacity(0.28), lineWidth: 1)
            )
            .overlay(shape.fill(Color.black.opacity(configuration.isPressed ? 0.2 : 0)))
            .contentShape(shape)
    }
}

/// A quieter button (Replay the day, Cancel, Restart chapter): an inked plaque, at least 52 pt high; on the desk a
/// plaque of dark wood with a bone rule.
struct QuietButtonStyle: ButtonStyle {
    var onDark = false
    /// A destructive choice (restarting the chapter): wax-red words and rule.
    var danger = false

    private var text: Color {
        if danger { return onDark ? Theme.rubricOnDesk : Theme.rubric }
        return onDark ? Theme.bone : Theme.ink
    }

    private var border: Color {
        if danger { return (onDark ? Theme.rubricOnDesk : Theme.rubric).opacity(0.9) }
        return onDark ? Theme.boneDim.opacity(0.8) : Theme.rule
    }

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        return configuration.label
            .font(Theme.caps(.headline))
            .foregroundStyle(text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(minWidth: 52, minHeight: 52)
            .background(shape.fill(onDark ? Theme.desk.opacity(0.7) : Theme.plaque.opacity(0.8)))
            .overlay(shape.strokeBorder(border, lineWidth: danger ? 1.5 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .inset(by: 3)
                    .strokeBorder(border.opacity(0.35), lineWidth: 1)
            )
            .overlay(shape.fill((onDark ? Color.white : Color.black).opacity(configuration.isPressed ? 0.14 : 0)))
            .contentShape(shape)
    }
}

/// The × of a card: a small inked box in a 44 pt touch area.
struct CardCloseButton: View {
    let identifier: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Theme.plaque.opacity(0.7)))
                .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous).strokeBorder(Theme.inkSoft, lineWidth: 1))
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
