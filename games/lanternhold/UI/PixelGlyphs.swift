import CoreGraphics
import SwiftUI

// Stage-3-interface, fix round 1 (the critic's highs 4 and 9, the director's note of 15.11. 11:39): no stock iOS glyph
// and no smooth gradient stands on night glass. The cards' signs are pixel glyphs on the game's 2 pt grid in the HUD
// kit's language (solid masses and 1 px strokes, one colour that follows the words, so a pressed plaque's amber sweep
// turns them deep navy with its words); the dawn is the kit's own sign (`hudDawn`), the one above the lord in the
// lantern moment, so the dawn report teaches the day line; the tiles behind portraits and sprites are a 3-step band
// dithered on the 2 pt grid; the gear stands on a small disc of the strip's glass. Plain reusable views with no
// dependence on stage-only state (the join dresses the other lanes' cards with them): `GlyphView`, `GlyphLabel`,
// `DitherGround`, `KitBlockView`, `KitDayLine`, `KitDawnSign`, `HUDKit.effects`, `GearDisc`, `SeparatedText`.

/// The glyphs. X a full pixel, x a second tone at half strength.
enum PixelGlyph: String, CaseIterable, Sendable {
    case play, flame, replay, close, lock, hourglass, check, bookmark, key, shield, warning, recruit, stranger,
         waves, paw, fog, bow, hammer, dice

    var grid: [String] {
        switch self {
        case .play:
            // Fix round 2 (the critic's high 1): a clean solid wedge, its slope even and its point two rows tall, so no
            // single row sticks out like a stub (the 7 x 7 read as a horn or a megaphone).
            return [
                "X......",
                "XXX....",
                "XXXXX..",
                "XXXXXXX",
                "XXXXXXX",
                "XXXXX..",
                "XXX....",
                "X......",
            ]
        case .flame:
            // Fix round 2: a teardrop with its tip leaning right and a hot hollow low inside, one colour (the old flame
            // read as a fist with a thumb).
            return [
                "....X..",
                "...XX..",
                "..XXX..",
                ".XXXX..",
                ".XXXXX.",
                "XXXXXXX",
                "XXX.XXX",
                "XX..XXX",
                ".XXXXX.",
            ]
        case .replay:
            return [
                "X.XXX..",
                "XX...X.",
                "XXX...X",
                "......X",
                "X.....X",
                ".X...X.",
                "..XXX..",
            ]
        case .close:
            return [
                "XX...XX",
                "XXX.XXX",
                ".XXXXX.",
                "..XXX..",
                ".XXXXX.",
                "XXX.XXX",
                "XX...XX",
            ]
        case .lock:
            return [
                "..XXX..",
                ".X...X.",
                ".X...X.",
                "XXXXXXX",
                "XXX.XXX",
                "XXX.XXX",
                "XXXXXXX",
            ]
        case .hourglass:
            return [
                "XXXXXXX",
                ".X...X.",
                ".XX.XX.",
                "..XXX..",
                ".X.X.X.",
                ".XXXXX.",
                "XXXXXXX",
            ]
        case .check:
            return [
                "......X",
                ".....XX",
                "X...XX.",
                "XX.XX..",
                ".XXX...",
                "..X....",
            ]
        case .bookmark:
            return [
                "XXXXX",
                "XXXXX",
                "XXXXX",
                "XXXXX",
                "XXXXX",
                "XX.XX",
                "X...X",
            ]
        case .key:
            return [
                ".XXX.....",
                "X...XXXXX",
                "X...X.X.X",
                ".XXX.....",
            ]
        case .shield:
            return [
                "XXXXXXX",
                "XxXXXXX",
                "XxXXXXX",
                "XxXXXXX",
                ".XxXXX.",
                "..XxX..",
                "...X...",
            ]
        case .warning:
            return [
                "...X...",
                "..XXX..",
                "..X.X..",
                ".XX.XX.",
                ".XXXXX.",
                "XXX.XXX",
                "XXXXXXX",
            ]
        case .recruit:
            return [
                "..X......",
                ".XXX..X..",
                "..X..XXX.",
                ".XXX..X..",
                "XXXXX....",
                "XXXXX....",
            ]
        case .stranger:
            return [
                "..X..XX.",
                ".XXX...X",
                "..X...X.",
                ".XXX..X.",
                "XXXXX...",
                "XXXXX.X.",
            ]
        case .waves:
            return [
                ".XX..XX",
                "X..XX..",
                ".......",
                ".XX..XX",
                "X..XX..",
            ]
        case .paw:
            return [
                ".X.X.",
                "X...X",
                ".XXX.",
                "XXXXX",
                ".XXX.",
            ]
        case .fog:
            return [
                "XXXX.XX",
                ".......",
                ".XX.XXX",
                ".......",
                "XXX.XX.",
            ]
        case .bow:
            return [
                ".XX....",
                "X..X...",
                "X...X.X",
                "XXXXXXX",
                "X...X.X",
                "X..X...",
                ".XX....",
            ]
        case .hammer:
            return [
                "XXXX...",
                "XXXXX..",
                "XXXX...",
                "..XX...",
                "...XX..",
                "....XX.",
                ".....XX",
            ]
        case .dice:
            return [
                "XXXXXXX",
                "X.XXX.X",
                "XXXXXXX",
                "XXX.XXX",
                "XXXXXXX",
                "X.XXX.X",
                "XXXXXXX",
            ]
        }
    }

    var size: (width: Int, height: Int) {
        (grid.first?.count ?? 0, grid.count)
    }
}

@MainActor
enum PixelGlyphImages {
    /// White on clear (a template: the view gives it the words' colour).
    static func image(_ glyph: PixelGlyph) -> CGImage? {
        NightGlassImages.image(key: "glyph-" + glyph.rawValue, grid: glyph.grid,
                               legend: ["X": NightGlass.Ink(rgb: 0xFFFFFF),
                                        "x": NightGlass.Ink(rgb: 0xFFFFFF, alpha: 128)])
    }
}

/// One glyph at 2 pt per game px, in the foreground style.
struct GlyphView: View {
    let glyph: PixelGlyph

    var body: some View {
        let size = glyph.size
        let unit = NightGlass.pointsPerPixel
        Group {
            if let image = PixelGlyphImages.image(glyph) {
                Image(decorative: image, scale: 1 / unit)
                    .renderingMode(.template)
                    .interpolation(.none)
            }
        }
        .frame(width: CGFloat(size.width) * unit, height: CGFloat(size.height) * unit)
        .accessibilityHidden(true)
    }
}

/// A label with a pixel glyph before its words (in place of `Label(_, systemImage:)`).
struct GlyphLabel<Words: View>: View {
    let glyph: PixelGlyph
    var spacing: CGFloat = 8
    @ViewBuilder let words: () -> Words

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            GlyphView(glyph: glyph)
            words()
        }
    }
}

extension GlyphLabel where Words == Text {
    init(_ key: LocalizedStringKey, glyph: PixelGlyph, spacing: CGFloat = 8) {
        self.glyph = glyph
        self.spacing = spacing
        self.words = { Text(key) }
    }

    init(verbatim text: String, glyph: PixelGlyph, spacing: CGFloat = 8) {
        self.glyph = glyph
        self.spacing = spacing
        self.words = { Text(verbatim: text) }
    }
}

// MARK: - The tiles' ground

/// The ground behind a portrait or a sprite: three bands of the palette, dithered into each other on the 2 pt grid
/// (the critic's high 9: no smooth gradient inside the glass).
enum TileGround: String, Sendable {
    /// Night blue, far blue, dusk rose (the court's portraits, the sprites).
    case dusk
    /// The realm's teal at night (the Burgherrin's own ground in the name entry).
    case teal

    var bands: (RGBA, RGBA, RGBA) {
        switch self {
        case .dusk: return (RGBA(0x262E5C), RGBA(0x4E5A82), RGBA(0xA04A60))
        case .teal: return (RGBA(0x1B3A4E), RGBA(0x2B6584), RGBA(0x3E7790))
        }
    }

    /// The ground `side` game px square: the top third, two dithered rows (a quarter, then half), the middle, two
    /// more, the bottom.
    func pixels(side: Int) -> PixelImage {
        let n = max(6, side)
        var image = PixelImage(width: n, height: n)
        let (a, b, c) = bands
        let first = n / 3 - 1
        let second = 2 * n / 3 - 1
        for y in 0..<n {
            for x in 0..<n {
                let colour: RGBA
                switch y {
                case ..<first: colour = a
                case first: colour = (x + y) % 4 == 0 ? b : a
                case first + 1: colour = (x + y) % 2 == 0 ? b : a
                case (first + 2)..<second: colour = b
                case second: colour = (x + y) % 4 == 0 ? c : b
                case second + 1: colour = (x + y) % 2 == 0 ? c : b
                default: colour = c
                }
                image[x, y] = colour
            }
        }
        return image
    }
}

@MainActor
enum TileGroundImages {
    private static var cache: [String: CGImage] = [:]

    static func image(_ ground: TileGround, side: Int) -> CGImage? {
        let key = "\(ground.rawValue)-\(side)"
        if let hit = cache[key] { return hit }
        guard let made = SpriteImages.cgImage(ground.pixels(side: side)) else { return nil }
        cache[key] = made
        return made
    }
}

/// The dithered ground filling `side` points square on the 2 pt grid (the last odd point takes the bottom band).
struct DitherGround: View {
    var ground: TileGround = .dusk
    let side: CGFloat

    var body: some View {
        let unit = NightGlass.pointsPerPixel
        let cells = max(6, Int((side / unit).rounded(.up)))
        Group {
            if let image = TileGroundImages.image(ground, side: cells) {
                Image(decorative: image, scale: 1 / unit)
                    .interpolation(.none)
                    .frame(width: CGFloat(cells) * unit, height: CGFloat(cells) * unit)
            }
        }
        .frame(width: side, height: side, alignment: .top)
        .clipped()
        .accessibilityHidden(true)
    }
}

// MARK: - The kit's pieces on a card

@MainActor
enum KitBlockImages {
    private static var cache: [String: CGImage] = [:]

    /// The pieces of a block composed from the atlas on whole game px.
    static func image(_ block: HUDKit.Block) -> CGImage? {
        let key = block.pieces.map { "\($0.sprite.rawValue).\($0.frame)@\($0.x),\($0.y)" }.joined(separator: ";")
        if let hit = cache[key] { return hit }
        guard block.width > 0 else { return nil }
        let rise = max(0, -(block.pieces.map(\.y).min() ?? 0))
        var canvas = PixelImage(width: block.width, height: block.height + rise)
        let layout = AtlasLayout.shared
        for piece in block.pieces {
            let cell = layout.cell(piece.sprite, frame: piece.frame)
            let pixels = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
            for y in 0..<pixels.height {
                for x in 0..<pixels.width {
                    let texel = pixels[x, y]
                    if texel.a > 0 { canvas[piece.x + x, piece.y + rise + y] = texel }
                }
            }
        }
        guard let made = SpriteImages.cgImage(canvas) else { return nil }
        cache[key] = made
        return made
    }
}

/// A block of the kit's pieces at `unit` points per game px (whole device px: 2 or 3).
struct KitBlockView: View {
    let block: HUDKit.Block
    var unit: CGFloat = 2

    var body: some View {
        let rise = max(0, -(block.pieces.map(\.y).min() ?? 0))
        Group {
            if let image = KitBlockImages.image(block) {
                Image(decorative: image, scale: 1 / unit)
                    .interpolation(.none)
            }
        }
        .frame(width: CGFloat(block.width) * unit, height: CGFloat(block.height + rise) * unit)
        .accessibilityHidden(true)
    }
}

/// The day line exactly as the lantern moment draws it above the lord: the kit's dawn sign and the day in its figures.
struct KitDayLine: View {
    let day: Int
    var unit: CGFloat = 3

    var body: some View {
        KitBlockView(block: HUDKit.group(sign: .hudDawn, number: day), unit: unit)
    }
}

/// The kit's dawn sign alone (the report's Continue).
struct KitDawnSign: View {
    var unit: CGFloat = 2

    var body: some View {
        KitBlockView(block: HUDKit.group(sign: .hudDawn), unit: unit)
    }
}

extension HUDKit {
    /// A sign and a signed number (a plus before a gain, the kit's minus before a loss).
    static func signedGroup(sign: SpriteID, frame: Int = 0, value: Int) -> Block {
        var block = Block()
        let rise = max(0, sign.size.height - rowHeight)
        block.pieces.append(Piece(sprite: sign, frame: frame, x: 0, y: -rise))
        let x = sign.size.width + signGap
        let frames = figureFrames(value, plus: true)
        for (index, figure) in frames.enumerated() {
            block.pieces.append(Piece(sprite: .hudFigures, frame: figure, x: x + advance * index, y: 0))
        }
        block.width = x + figuresWidth(frames.count)
        block.height = rowHeight
        return block
    }

    /// What a choice changed, as the kit shows a change above the lord: the coin, the face, the people, each with its
    /// signed figure; empty when none changed.
    static func effects(gold: Int, happiness: Int, citizens: Int) -> Block {
        var groups: [Block] = []
        if gold != 0 { groups.append(signedGroup(sign: .hudCoin, value: gold)) }
        if happiness != 0 {
            groups.append(signedGroup(sign: .hudFace, frame: faceFrame(happiness: happiness > 0 ? 85 : 20),
                                      value: happiness))
        }
        if citizens != 0 { groups.append(signedGroup(sign: .hudPeople, value: citizens)) }
        return row(groups)
    }
}

// MARK: - The gear's disc

@MainActor
enum GearDiscImages {
    private static var image: CGImage?

    /// 16 x 16 game px: the strip's navy glass in a disc, its brass line 1 px inside the edge.
    static func disc() -> CGImage? {
        if let image { return image }
        var rows: [String] = []
        for y in 0..<16 {
            var row = ""
            for x in 0..<16 {
                let dx = Double(x) + 0.5 - 8
                let dy = Double(y) + 0.5 - 8
                let d = (dx * dx + dy * dy).squareRoot()
                row.append(d > 7.9 ? "." : (d > 6.9 ? "f" : (d > 5.9 ? "l" : "f")))
            }
            rows.append(row)
        }
        image = NightGlassImages.image(key: "gear-disc", grid: rows,
                                       legend: ["f": NightGlass.navyInk, "l": NightGlass.brassInk])
        return image
    }
}

/// The gear's glass disc, 32 pt (HUD.md: the gear reads on any ground; the director's note of 15.11. 11:39).
struct GearDisc: View {
    var body: some View {
        Group {
            if let image = GearDiscImages.disc() {
                Image(decorative: image, scale: 1 / NightGlass.pointsPerPixel)
                    .interpolation(.none)
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

// MARK: - Typesetting

/// The cards' inner padding from the pane's edge (fix round 1, the critic's high 8: one padding on every card; the
/// counsel's italic stood 4 pt from its line).
enum GlassMetrics {
    static let inset: CGFloat = 14
}

/// Facts joined by " · " that never leave the separator at a line's end (fix round 1, the critic's high 8): the line
/// breaks between the facts, and the dot goes with the break. One line when it fits, else two (the last fact or the
/// first alone), else one fact a line (a fact longer than the column wraps inside itself).
struct SeparatedText: View {
    let text: String
    let style: Font.TextStyle

    var body: some View {
        let parts = text.components(separatedBy: " · ")
        if parts.count < 2 {
            Text(inked: text, style)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            ViewThatFits(in: .horizontal) {
                line(parts)
                if parts.count >= 3 {
                    VStack(alignment: .leading, spacing: 0) {
                        line(Array(parts.dropLast()))
                        line([parts[parts.count - 1]])
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        line([parts[0]])
                        line(Array(parts.dropFirst()))
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                        Text(inked: part, style)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func line(_ parts: [String]) -> some View {
        Text(inked: parts.joined(separator: " · "), style)
            .lineLimit(1)
            .fixedSize()
    }
}
