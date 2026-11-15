import CoreGraphics
import SwiftUI
import UIKit

/// Night glass (docs/TITLE.md section 4; HUD.md rule 3): no parchment anywhere (Louis, 15.11.2026). Every card, sheet
/// and plaque stands on a pane of the night's navy over the world, drawn on the game's pixel grid (one game pixel is
/// 2 pt, 6 device pixels on iPhone 17 Pro) and scaled with nearest neighbour only: one brass line of 1 game px set
/// 2 game px inside the edge (1 on a choice plaque, whose words stand closer to its edge), the corners notched by
/// 1 game px. No shadow, gradient, texture, wax or seal. The pixels are built here from the same grids and colours as
/// `tools/glassart.py` (which writes them as PNGs to `tools/glass/` for the proofs; `glassart.py check` compares this
/// file with it), so nothing enters the atlas or the bundle. Not wired in yet: the stage lane or the join swaps the old
/// skin for it (ci-out/director/night-glass.md, the wiring note).
enum NightGlass {
    // MARK: Colours (glassart.py COLOURS; palette names from tools/palette.txt)

    /// The pane: palette nightBlue, at 88 % over the world.
    static let navy = Color(hex: 0x121C3B)
    static let paneAlpha: Double = 0.878
    /// The line and the words on a pressed plaque, the switch's slot: palette nightDeep.
    static let navyDeep = Color(hex: 0x0A1124)
    /// The brass line: palette straw (the coin's shaded rim in the HUD kit).
    static let brass = Color(hex: 0xA68A54)
    /// Running text: palette parchment, the HUD kit's bone. 7.8:1 on the pane over white, 11.6:1 over black.
    static let bone = Color(hex: 0xDED2B8)
    /// Names, headings, the chosen state, a marked plaque's line: palette fireGold. 7.5:1 over white.
    static let lanternGold = Color(hex: 0xFFC65A)
    /// A pressed plaque's fill: the lantern's light (ART-look2.md "Warm pools"). navyDeep on it 9.5:1.
    static let amber = Color(hex: 0xFFA34D)
    /// Secondary lines (the muted blue-grey): palette mistLight. 7.2:1 over white.
    static let mist = Color(hex: 0xC5CBD9)
    /// Words that cannot be chosen: palette mist.
    static let mistDim = Color(hex: 0x98A1BB)
    /// The line of a plaque that cannot be paid: palette mistDark.
    static let mistDark = Color(hex: 0x6A7393)
    /// Separators (the old ink rule): palette nightHaze.
    static let haze = Color(hex: 0x2F3F72)
    /// The lifted face of a sheet's main button: palette nightSlate, at 200 of 255.
    static let slate = Color(hex: 0x1E2B52)
    /// The line of a destructive choice: palette ember.
    static let ember = Color(hex: 0xD9481F)

    /// Points per game pixel: whole device pixels on every iPhone.
    static let pointsPerPixel: CGFloat = 2

    // MARK: Grids (f fill, l line, . clear)

    /// A card or a sheet: the line 2 game px inside the edge. Caps 4.
    static let paneGrid = [
        ".fffffff.",
        "fffffffff",
        "fflllllff",
        "fflffflff",
        "fflffflff",
        "fflffflff",
        "fflllllff",
        "fffffffff",
        ".fffffff.",
    ]

    /// A choice plaque: the line 1 game px inside the edge. Caps 3.
    static let plaqueGrid = [
        ".fffff.",
        "flllllf",
        "flffflf",
        "flffflf",
        "flffflf",
        "flllllf",
        ".fffff.",
    ]

    /// A plaque inside a pane (a sheet's buttons and rows): the line on its own edge; no second fill, except the
    /// main button's lifted slate. Caps 4.
    static let insetGrid = [
        ".lllllll.",
        "lfffffffl",
        "lfffffffl",
        "lfffffffl",
        "lfffffffl",
        "lfffffffl",
        "lfffffffl",
        "lfffffffl",
        ".lllllll.",
    ]

    /// A portrait's brass line, 1 game px hugging the picture, its corners notched; no mat. Caps 2.
    static let portraitGrid = [
        ".....",
        "..l..",
        ".l.l.",
        "..l..",
        ".....",
    ]

    /// The horn's ribbon (and the dawn report's banners), `height` game px high: the pane with both ends cut in a V
    /// of 1:1 pixel stairs, the line 2 game px inside the top and bottom and 3 inside the stairs. The middle column
    /// stretches (glassart.py ribbon_grid).
    static func ribbonGrid(height: Int) -> (rows: [String], cap: Int) {
        let depth = height / 2
        let cap = depth + 4
        let width = 2 * cap + 1
        let mid = height / 2
        var rows: [String] = []
        for y in 0..<height {
            let left = depth - abs(y - mid)
            var row = ""
            for x in 0..<width {
                let right = width - 1 - left
                if x < left || x > right {
                    row.append(".")
                } else if y >= 2 && y <= height - 3 && (x - left == 3 || right - x == 3) {
                    row.append("l")
                } else if (y == 2 || y == height - 3) && x >= left + 3 && x <= right - 3 {
                    row.append("l")
                } else {
                    row.append("f")
                }
            }
            rows.append(row)
        }
        return (rows, cap)
    }

    /// The pause sheet's switch, 24x12 game px: a slot with a square knob (no wax seal). k the knob's edge, m its
    /// face, s the slot (glassart.py switch_grid).
    static func switchGrid(on: Bool) -> [String] {
        let left = on ? 12 : 2
        var rows: [String] = []
        for y in 0..<12 {
            var row = ""
            for x in 0..<24 {
                if (x == 0 || x == 23) && (y == 0 || y == 11) {
                    row.append(".")
                } else if x == 0 || x == 23 || y == 0 || y == 11 {
                    row.append("l")
                } else if x >= left && x <= left + 9 && y >= 2 && y <= 9 {
                    let corner = (x == left || x == left + 9) && (y == 2 || y == 9)
                    let edge = x == left || x == left + 9 || y == 2 || y == 9
                    row.append(corner ? "s" : (edge ? "k" : "m"))
                } else {
                    row.append("s")
                }
            }
            rows.append(row)
        }
        return rows
    }

    // MARK: Skins

    /// One pixel's colour as 0xRRGGBB and an alpha of 0...255.
    struct Ink: Sendable, Hashable {
        var rgb: UInt32
        var alpha: UInt8 = 255
    }

    /// The pane's navy at 224 of 255 (paneAlpha).
    static let navyInk = Ink(rgb: 0x121C3B, alpha: 224)
    static let brassInk = Ink(rgb: 0xA68A54)

    /// The skins of the pane family.
    enum Skin: String, Sendable, CaseIterable {
        /// A card or a sheet.
        case panel
        /// A choice at rest.
        case plaque
        /// The favoured or chosen choice: the line in lantern gold.
        case plaqueMarked
        /// Pressed: filled with lantern amber, the line in deep navy (the words turn deep navy).
        case plaquePressed
        /// Cannot be paid: the line in dark mist (the words in dim mist).
        case plaqueOff
        /// A destructive choice: the line in ember (the words stay bone).
        case plaqueDanger
        /// A plaque inside a pane: no second fill.
        case inset
        /// The main button of a sheet (Resume, Continue): the inset's line in lantern gold on a lifted slate face.
        case insetMarked
        /// A destructive choice inside a sheet.
        case insetDanger

        var grid: [String] {
            switch self {
            case .panel: return NightGlass.paneGrid
            case .inset, .insetMarked, .insetDanger: return NightGlass.insetGrid
            default: return NightGlass.plaqueGrid
            }
        }

        var cap: Int { (grid.count - 1) / 2 }

        var fill: Ink? {
            switch self {
            case .plaquePressed: return Ink(rgb: 0xFFA34D)
            case .insetMarked: return Ink(rgb: 0x1E2B52, alpha: 200)
            case .inset, .insetDanger: return nil
            default: return NightGlass.navyInk
            }
        }

        var line: Ink {
            switch self {
            case .plaqueMarked, .insetMarked: return Ink(rgb: 0xFFC65A)
            case .plaquePressed: return Ink(rgb: 0x0A1124)
            case .plaqueOff: return Ink(rgb: 0x6A7393)
            case .plaqueDanger, .insetDanger: return Ink(rgb: 0xD9481F)
            default: return NightGlass.brassInk
            }
        }
    }
}

// MARK: - Pixels

/// The skins' pixels, built once from the grids (whole pixels, no smoothing) and cached.
@MainActor
enum NightGlassImages {
    private static var cache: [String: CGImage] = [:]

    static func image(_ skin: NightGlass.Skin) -> CGImage? {
        var legend: [Character: NightGlass.Ink] = ["l": skin.line]
        if let fill = skin.fill { legend["f"] = fill }
        return image(key: "skin-" + skin.rawValue, grid: skin.grid, legend: legend)
    }

    static func portraitLine() -> CGImage? {
        image(key: "portrait", grid: NightGlass.portraitGrid, legend: ["l": NightGlass.brassInk])
    }

    static func ribbon(height: Int) -> CGImage? {
        image(key: "ribbon-\(height)", grid: NightGlass.ribbonGrid(height: height).rows,
              legend: ["f": NightGlass.navyInk, "l": NightGlass.brassInk])
    }

    static func toggle(on: Bool) -> CGImage? {
        let legend: [Character: NightGlass.Ink] = [
            "l": NightGlass.brassInk,
            "s": NightGlass.Ink(rgb: 0x0A1124, alpha: 235),
            "k": NightGlass.Ink(rgb: on ? 0xFFC65A : 0x6A7393),
            "m": NightGlass.Ink(rgb: on ? 0xFFA34D : 0x2F3F72),
        ]
        return image(key: on ? "switch-on" : "switch-off", grid: NightGlass.switchGrid(on: on), legend: legend)
    }

    /// Draws a grid one pixel per character into a premultiplied sRGB bitmap.
    static func image(key: String, grid: [String], legend: [Character: NightGlass.Ink]) -> CGImage? {
        if let hit = cache[key] { return hit }
        let height = grid.count
        let width = grid.first?.count ?? 0
        guard width > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for (y, row) in grid.enumerated() {
            for (x, character) in row.enumerated() {
                guard let ink = legend[character] else { continue }
                let alpha = UInt32(ink.alpha)
                let offset = (y * width + x) * 4
                // Premultiplied: each channel times alpha / 255, rounded.
                bytes[offset] = UInt8((((ink.rgb >> 16) & 0xFF) * alpha + 127) / 255)
                bytes[offset + 1] = UInt8((((ink.rgb >> 8) & 0xFF) * alpha + 127) / 255)
                bytes[offset + 2] = UInt8(((ink.rgb & 0xFF) * alpha + 127) / 255)
                bytes[offset + 3] = ink.alpha
            }
        }
        let made: CGImage? = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            return context.makeImage()
        }
        if let made { cache[key] = made }
        return made
    }
}

// MARK: - Views

/// A nine-slice of night glass: the caps at whole game pixels, the middle stretched, never smoothed.
struct GlassSkinView: View {
    var skin: NightGlass.Skin = .panel

    var body: some View {
        GlassNineSlice(image: NightGlassImages.image(skin), cap: skin.cap)
    }
}

/// A grid image at 2 pt per pixel with fixed caps (`vertical: false` stretches only across, for the ribbon).
struct GlassNineSlice: View {
    let image: CGImage?
    let cap: Int
    var vertical = true

    var body: some View {
        if let image {
            let points = CGFloat(cap) * NightGlass.pointsPerPixel
            Image(decorative: image, scale: 1 / NightGlass.pointsPerPixel)
                .resizable(capInsets: EdgeInsets(top: vertical ? points : 0, leading: points,
                                                 bottom: vertical ? points : 0, trailing: points),
                           resizingMode: .stretch)
                .interpolation(.none)
                .accessibilityHidden(true)
        } else {
            NightGlass.navy.opacity(NightGlass.paneAlpha)
                .accessibilityHidden(true)
        }
    }
}

/// The pane of a card or a sheet (replaces ParchmentBackground, SlipBackground and NightBackground).
struct GlassPanelBackground: View {
    var body: some View {
        GlassSkinView(skin: .panel)
    }
}

/// A plaque's pane at rest (replaces PlaqueBackground where the style below cannot be used, e.g. a row of a card).
struct GlassPlaqueBackground: View {
    var enabled = true
    var marked = false
    /// Inside a pane: the inset skin, so the pane is not darkened twice.
    var inside = false

    var body: some View {
        GlassSkinView(skin: skin)
    }

    private var skin: NightGlass.Skin {
        if inside { return marked ? .insetMarked : .inset }
        if !enabled { return .plaqueOff }
        return marked ? .plaqueMarked : .plaque
    }
}

/// A choice on night glass. Pressed, lantern amber fills it from the left in 0.12 s (at once with Reduce Motion), the
/// words under the fill turn deep navy, and one haptic tick answers (`haptics`: pass the player's setting). The label
/// keeps its own padding and frame; words inside it must not set their own colour, or they keep it under the fill.
struct GlassPlaqueStyle: ButtonStyle {
    var marked = false
    var danger = false
    /// Inside a pane (a sheet's buttons): the inset skins.
    var inside = false
    var haptics = true
    /// Words in lantern gold at rest (a sheet's main button); otherwise bone.
    var goldWords = false

    func makeBody(configuration: Configuration) -> some View {
        GlassPlaqueBody(label: configuration.label, isPressed: configuration.isPressed, marked: marked, danger: danger,
                        inside: inside, haptics: haptics, goldWords: goldWords)
    }
}

/// The main button of a card or a sheet on night glass (Continue, Resume, Begin, a second chance), with
/// GoldButtonStyle's metrics: small capitals, 22 x 8 pt of padding, 52 pt or more. Inside a pane its line and words
/// are lantern gold.
struct GlassMainButtonStyle: ButtonStyle {
    var inside = true
    var haptics = true

    func makeBody(configuration: Configuration) -> some View {
        GlassPlaqueBody(label: configuration.label
                            .font(Theme.caps(.headline))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 8)
                            .frame(minWidth: 52, minHeight: 52),
                        isPressed: configuration.isPressed, marked: true, danger: false, inside: inside,
                        haptics: haptics, goldWords: true)
    }
}

/// A quieter button on night glass (Replay the day, Cancel, Restart chapter), with QuietButtonStyle's metrics:
/// small capitals, 20 x 8 pt of padding, 52 pt or more; `danger` draws its line in ember.
struct GlassQuietButtonStyle: ButtonStyle {
    var danger = false
    var inside = true
    var haptics = true

    func makeBody(configuration: Configuration) -> some View {
        GlassPlaqueBody(label: configuration.label
                            .font(Theme.caps(.headline))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .frame(minWidth: 52, minHeight: 52),
                        isPressed: configuration.isPressed, marked: false, danger: danger, inside: inside,
                        haptics: haptics, goldWords: false)
    }
}

/// The plaque's body for the three styles: the skin at rest, the amber sweep over it, the words twice (at rest, and
/// deep navy under the sweep).
struct GlassPlaqueBody<Label: View>: View {
    let label: Label
    let isPressed: Bool
    var marked = false
    var danger = false
    var inside = false
    var haptics = true
    var goldWords = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = isPressed && isEnabled
        ZStack {
            GlassSkinView(skin: restSkin)
            GlassSkinView(skin: .plaquePressed)
                .mask(alignment: .leading) { sweep(pressed) }
            label
                .foregroundStyle(restWords)
            label
                .foregroundStyle(NightGlass.navyDeep)
                .mask(alignment: .leading) { sweep(pressed) }
                .accessibilityHidden(true)
        }
        .animation(reduceMotion ? nil : .linear(duration: 0.12), value: pressed)
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: pressed) { _, now in now && haptics }
    }

    /// The fill's mask: the whole plaque, scaled from the leading edge.
    private func sweep(_ pressed: Bool) -> some View {
        Rectangle()
            .scaleEffect(x: pressed ? 1 : 0.0001, y: 1, anchor: .leading)
    }

    private var restSkin: NightGlass.Skin {
        if inside {
            if danger { return .insetDanger }
            return marked ? .insetMarked : .inset
        }
        if !isEnabled { return .plaqueOff }
        if danger { return .plaqueDanger }
        return marked ? .plaqueMarked : .plaque
    }

    private var restWords: Color {
        if !isEnabled { return NightGlass.mistDim }
        return goldWords ? NightGlass.lanternGold : NightGlass.bone
    }
}

/// A portrait's brass line, 1 game px hugging the picture, its corners notched; no mat. Caps 2.
    static let portraitGrid = [
        ".....",
        "..l..",
        ".l.l.",
        "..l..",
        ".....",
    ]

    /// The horn's ribbon (and the dawn report's banners), `height` game px high: the pane with both ends cut in a V
    /// of 1:1 pixel stairs, the line 2 game px inside the top and bottom and 3 inside the stairs. The middle column
    /// stretches (glassart.py ribbon_grid).
    static func ribbonGrid(height: Int) -> (rows: [String], cap: Int) {
        let depth = height / 2
        let cap = depth + 4
        let width = 2 * cap + 1
        let mid = height / 2
        var rows: [String] = []
        for y in 0..<height {
            let left = depth - abs(y - mid)
            var row = ""
            for x in 0..<width {
                let right = width - 1 - left
                if x < left || x > right {
                    row.append(".")
                } else if y >= 2 && y <= height - 3 && (x - left == 3 || right - x == 3) {
                    row.append("l")
                } else if (y == 2 || y == height - 3) && x >= left + 3 && x <= right - 3 {
                    row.append("l")
                } else {
                    row.append("f")
                }
            }
            rows.append(row)
        }
        return (rows, cap)
    }

    /// The pause sheet's switch, 24x12 game px: a slot with a square knob (no wax seal). k the knob's edge, m its
    /// face, s the slot (glassart.py switch_grid).
    static func switchGrid(on: Bool) -> [String] {
        let left = on ? 12 : 2
        var rows: [String] = []
        for y in 0..<12 {
            var row = ""
            for x in 0..<24 {
                if (x == 0 || x == 23) && (y == 0 || y == 11) {
                    row.append(".")
                } else if x == 0 || x == 23 || y == 0 || y == 11 {
                    row.append("l")
                } else if x >= left && x <= left + 9 && y >= 2 && y <= 9 {
                    let corner = (x == left || x == left + 9) && (y == 2 || y == 9)
                    let edge = x == left || x == left + 9 || y == 2 || y == 9
                    row.append(corner ? "s" : (edge ? "k" : "m"))
                } else {
                    row.append("s")
                }
            }
            rows.append(row)
        }
        return rows
    }

    // MARK: Skins

    /// One pixel's colour as 0xRRGGBB and an alpha of 0...255.
    struct Ink: Sendable, Hashable {
        var rgb: UInt32
        var alpha: UInt8 = 255
    }

    /// The pane's navy at 224 of 255 (paneAlpha).
    static let navyInk = Ink(rgb: 0x121C3B, alpha: 224)
    static let brassInk = Ink(rgb: 0xA68A54)

    /// The skins of the pane family.
    enum Skin: String, Sendable, CaseIterable {
        /// A card or a sheet.
        case panel
        /// A choice at rest.
        case plaque
        /// The favoured or chosen choice: the line in lantern gold.
        case plaqueMarked
        /// Pressed: filled with lantern amber, the line in deep navy (the words turn deep navy).
        case plaquePressed
        /// Cannot be paid: the line in dark mist (the words in dim mist).
        case plaqueOff
        /// A destructive choice: the line in ember (the words stay bone).
        case plaqueDanger
        /// A plaque inside a pane: no second fill.
        case inset
        /// The main button of a sheet (Resume, Continue): the inset's line in lantern gold on a lifted slate face.
        case insetMarked
        /// A destructive choice inside a sheet.
        case insetDanger

        var grid: [String] {
            switch self {
            case .panel: return NightGlass.paneGrid
            case .inset, .insetMarked, .insetDanger: return NightGlass.insetGrid
            default: return NightGlass.plaqueGrid
            }
        }

        var cap: Int { (grid.count - 1) / 2 }

        var fill: Ink? {
            switch self {
            case .plaquePressed: return Ink(rgb: 0xFFA34D)
            case .insetMarked: return Ink(rgb: 0x1E2B52, alpha: 200)
            case .inset, .insetDanger: return nil
            default: return NightGlass.navyInk
            }
        }

        var line: Ink {
            switch self {
            case .plaqueMarked, .insetMarked: return Ink(rgb: 0xFFC65A)
            case .plaquePressed: return Ink(rgb: 0x0A1124)
            case .plaqueOff: return Ink(rgb: 0x6A7393)
            case .plaqueDanger, .insetDanger: return Ink(rgb: 0xD9481F)
            default: return NightGlass.brassInk
            }
        }
    }
}

// MARK: - Pixels

/// The skins' pixels, built once from the grids (whole pixels, no smoothing) and cached.
@MainActor
enum NightGlassImages {
    private static var cache: [String: CGImage] = [:]

    static func image(_ skin: NightGlass.Skin) -> CGImage? {
        var legend: [Character: NightGlass.Ink] = ["l": skin.line]
        if let fill = skin.fill { legend["f"] = fill }
        return image(key: "skin-" + skin.rawValue, grid: skin.grid, legend: legend)
    }

    static func portraitLine() -> CGImage? {
        image(key: "portrait", grid: NightGlass.portraitGrid, legend: ["l": NightGlass.brassInk])
    }

    static func ribbon(height: Int) -> CGImage? {
        image(key: "ribbon-\(height)", grid: NightGlass.ribbonGrid(height: height).rows,
              legend: ["f": NightGlass.navyInk, "l": NightGlass.brassInk])
    }

    static func toggle(on: Bool) -> CGImage? {
        let legend: [Character: NightGlass.Ink] = [
            "l": NightGlass.brassInk,
            "s": NightGlass.Ink(rgb: 0x0A1124, alpha: 235),
            "k": NightGlass.Ink(rgb: on ? 0xFFC65A : 0x6A7393),
            "m": NightGlass.Ink(rgb: on ? 0xFFA34D : 0x2F3F72),
        ]
        return image(key: on ? "switch-on" : "switch-off", grid: NightGlass.switchGrid(on: on), legend: legend)
    }

    /// Draws a grid one pixel per character into a premultiplied sRGB bitmap.
    static func image(key: String, grid: [String], legend: [Character: NightGlass.Ink]) -> CGImage? {
        if let hit = cache[key] { return hit }
        let height = grid.count
        let width = grid.first?.count ?? 0
        guard width > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for (y, row) in grid.enumerated() {
            for (x, character) in row.enumerated() {
                guard let ink = legend[character] else { continue }
                let alpha = UInt32(ink.alpha)
                let offset = (y * width + x) * 4
                // Premultiplied: each channel times alpha / 255, rounded.
                bytes[offset] = UInt8((((ink.rgb >> 16) & 0xFF) * alpha + 127) / 255)
                bytes[offset + 1] = UInt8((((ink.rgb >> 8) & 0xFF) * alpha + 127) / 255)
                bytes[offset + 2] = UInt8(((ink.rgb & 0xFF) * alpha + 127) / 255)
                bytes[offset + 3] = ink.alpha
            }
        }
        let made: CGImage? = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            return context.makeImage()
        }
        if let made { cache[key] = made }
        return made
    }
}

// MARK: - Views

/// A nine-slice of night glass: the caps at whole game pixels, the middle stretched, never smoothed.
struct GlassSkinView: View {
    var skin: NightGlass.Skin = .panel

    var body: some View {
        GlassNineSlice(image: NightGlassImages.image(skin), cap: skin.cap)
    }
}

/// A grid image at 2 pt per pixel with fixed caps (`vertical: false` stretches only across, for the ribbon).
struct GlassNineSlice: View {
    let image: CGImage?
    let cap: Int
    var vertical = true

    var body: some View {
        if let image {
            let points = CGFloat(cap) * NightGlass.pointsPerPixel
            Image(decorative: image, scale: 1 / NightGlass.pointsPerPixel)
                .resizable(capInsets: EdgeInsets(top: vertical ? points : 0, leading: points,
                                                 bottom: vertical ? points : 0, trailing: points),
                           resizingMode: .stretch)
                .interpolation(.none)
                .accessibilityHidden(true)
        } else {
            NightGlass.navy.opacity(NightGlass.paneAlpha)
                .accessibilityHidden(true)
        }
    }
}

/// The pane of a card or a sheet (replaces ParchmentBackground, SlipBackground and NightBackground).
struct GlassPanelBackground: View {
    var body: some View {
        GlassSkinView(skin: .panel)
    }
}

/// A plaque's pane at rest (replaces PlaqueBackground where the style below cannot be used, e.g. a row of a card).
struct GlassPlaqueBackground: View {
    var enabled = true
    var marked = false
    /// Inside a pane: the inset skin, so the pane is not darkened twice.
    var inside = false

    var body: some View {
        GlassSkinView(skin: skin)
    }

    private var skin: NightGlass.Skin {
        if inside { return marked ? .insetMarked : .inset }
        if !enabled { return .plaqueOff }
        return marked ? .plaqueMarked : .plaque
    }
}

/// A choice on night glass. Pressed, lantern amber fills it from the left in 0.12 s (at once with Reduce Motion), the
/// words under the fill turn deep navy, and one haptic tick answers (`haptics`: pass the player's setting). The label
/// keeps its own padding and frame; words inside it must not set their own colour, or they keep it under the fill.
struct GlassPlaqueStyle: ButtonStyle {
    var marked = false
    var danger = false
    /// Inside a pane (a sheet's buttons): the inset skins.
    var inside = false
    var haptics = true
    /// Words in lantern gold at rest (a sheet's main button); otherwise bone.
    var goldWords = false

    func makeBody(configuration: Configuration) -> some View {
        GlassPlaqueBody(configuration: configuration, marked: marked, danger: danger, inside: inside,
                        haptics: haptics, goldWords: goldWords)
    }
}

private struct GlassPlaqueBody: View {
    let configuration: ButtonStyleConfiguration
    let marked: Bool
    let danger: Bool
    let inside: Bool
    let haptics: Bool
    let goldWords: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pressed = configuration.isPressed && isEnabled
        ZStack {
            GlassSkinView(skin: restSkin)
            GlassSkinView(skin: .plaquePressed)
                .mask(alignment: .leading) { sweep(pressed) }
            configuration.label
                .foregroundStyle(restWords)
            configuration.label
                .foregroundStyle(NightGlass.navyDeep)
                .mask(alignment: .leading) { sweep(pressed) }
                .accessibilityHidden(true)
        }
        .animation(reduceMotion ? nil : .linear(duration: 0.12), value: pressed)
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: pressed) { _, now in now && haptics }
    }

    /// The fill's mask: the whole plaque, scaled from the leading edge.
    private func sweep(_ pressed: Bool) -> some View {
        Rectangle()
            .scaleEffect(x: pressed ? 1 : 0.0001, y: 1, anchor: .leading)
    }

    private var restSkin: NightGlass.Skin {
        if inside {
            if danger { return .insetDanger }
            return marked ? .insetMarked : .inset
        }
        if !isEnabled { return .plaqueOff }
        if danger { return .plaqueDanger }
        return marked ? .plaqueMarked : .plaque
    }

    private var restWords: Color {
        if !isEnabled { return NightGlass.mistDim }
        return goldWords ? NightGlass.lanternGold : NightGlass.bone
    }
}

/// A portrait's brass line (replaces PortraitTile's ink frame and gold hairline): lay it over the tile at the tile's
/// size; the picture fills the tile less 2 game px (4 pt) on every side, as before, and the ring outside it is pane.
struct GlassPortraitLine: View {
    var body: some View {
        GlassNineSlice(image: NightGlassImages.portraitLine(), cap: 2)
    }
}

/// The horn's ribbon and the report's banners (replaces RibbonShape's fill and stroke), `height` game px high
/// (15 = 30 pt; 13 = 26 pt), as wide as offered.
struct GlassRibbonBackground: View {
    var height = 15

    var body: some View {
        GlassNineSlice(image: NightGlassImages.ribbon(height: height), cap: NightGlass.ribbonGrid(height: height).cap,
                       vertical: false)
            .frame(height: CGFloat(height) * NightGlass.pointsPerPixel)
    }
}

/// The pause sheet's switch face (replaces the wax-seal knob), 48 x 24 pt; the row stays the touch target.
struct GlassSwitchFace: View {
    let isOn: Bool

    var body: some View {
        Group {
            if let image = NightGlassImages.toggle(on: isOn) {
                Image(decorative: image, scale: 1 / NightGlass.pointsPerPixel)
                    .interpolation(.none)
            }
        }
        .frame(width: 24 * NightGlass.pointsPerPixel, height: 12 * NightGlass.pointsPerPixel)
        .accessibilityHidden(true)
    }
}

/// A separator on a pane (replaces InkRule): 1 game px of night haze.
struct GlassRule: View {
    var body: some View {
        Rectangle()
            .fill(NightGlass.haze)
            .frame(height: NightGlass.pointsPerPixel)
            .accessibilityHidden(true)
    }
}

/// A heading's flourish on a pane (replaces FlourishRule): two haze rules and a pixel lozenge in lantern gold.
struct GlassFlourish: View {
    var body: some View {
        let unit = NightGlass.pointsPerPixel
        HStack(spacing: unit * 3) {
            GlassRule()
            GlassGem()
            GlassRule()
        }
        .frame(height: unit * 3)
        .accessibilityHidden(true)
    }
}

/// The flourish's lozenge, 3x3 game px.
struct GlassGem: View {
    var body: some View {
        let unit = NightGlass.pointsPerPixel
        ZStack {
            Rectangle().fill(NightGlass.lanternGold).frame(width: unit * 3, height: unit)
            Rectangle().fill(NightGlass.lanternGold).frame(width: unit, height: unit * 3)
        }
        .frame(width: unit * 3, height: unit * 3)
        .accessibilityHidden(true)
    }
}
