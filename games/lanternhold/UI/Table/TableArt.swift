import CoreGraphics
import SwiftUI

/// The Lantern Table's pixel art (`Resources/TableArt/*.png`, `tools/tableart.py`; QUESTS.md 6): decoded texel for
/// texel, cut into frames, and composed into one picture of the table top and one of the rail, which the screen shows
/// at whole device pixels per texel and never smooths. The art stays out of the world's atlas: only this screen draws it.
@MainActor
enum TableArt {
    private static var cache: [String: PixelImage] = [:]
    private static var images: [String: CGImage] = [:]

    /// A PNG of the table's art (nil when the bundle lacks it: the screen then draws without it).
    static func pixels(_ name: String) -> PixelImage? {
        if let hit = cache[name] { return hit }
        let bundle = Bundle.main
        let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "TableArt")
            ?? bundle.url(forResource: name, withExtension: "png")
        guard let url, let image = PNGDecoder.load(url: url) else { return nil }
        cache[name] = image
        return image
    }

    /// Frame `index` of a horizontal strip whose frames are `width` texels wide.
    static func frame(_ name: String, _ index: Int, width: Int) -> PixelImage? {
        guard let strip = pixels(name) else { return nil }
        return strip.cropped(x: index * width, y: 0, width: width, height: strip.height)
    }

    /// A strip's frame as a CGImage, cached.
    static func image(_ name: String, frame index: Int = 0, width: Int? = nil) -> CGImage? {
        let key = "\(name)#\(index)"
        if let hit = images[key] { return hit }
        let picture: PixelImage?
        if let width { picture = frame(name, index, width: width) } else { picture = pixels(name) }
        guard let picture, let made = SpriteImages.cgImage(picture) else { return nil }
        images[key] = made
        return made
    }
}

extension PixelImage {
    /// Draws `other` with its top-left corner at (x, y): opaque texels replace, clear ones leave (binary alpha).
    mutating func tableStamp(_ other: PixelImage?, x: Int, y: Int) {
        guard let other else { return }
        for row in 0..<other.height {
            for column in 0..<other.width {
                let texel = other[column, row]
                if texel.a > 0 { self[x + column, y + row] = texel }
            }
        }
    }
}

/// The few palette colours the screen draws itself (tools/palette.txt).
enum TableInk {
    static let fireWhite = RGBA(r: 0xFF, g: 0xF2, b: 0xC2)
    static let fireGold = RGBA(r: 0xFF, g: 0xC6, b: 0x5A)
    static let fireOrange = RGBA(r: 0xFF, g: 0x8A, b: 0x2A)
    static let strawLight = RGBA(r: 0xC4, g: 0xA8, b: 0x72)
    static let woodDark = RGBA(r: 0x3A, g: 0x26, b: 0x1E)
}

/// The table top as one picture: the carving (or the cloth of day 1), the bare wood's scratches and the span when the
/// realm has them, the lines of light, the dotted road of the open slip, and the pins (lit where a sending waits).
struct TablePicture: Equatable {
    enum Pin: Equatable {
        case dull, lit
    }

    var covered = false
    var west1 = false
    var west2 = false
    var span = false
    /// Each place's pin (a place missing here shows no pin: a lantern stands on it).
    var pins: [String: Pin] = [:]
    /// The lines of light: the place and how far the light has crept.
    var lines: [String: Double] = [:]
    /// The open slip's road, dotted.
    var preview: String?

    static let pinKinds = ["brass", "iron", "varn", "brine", "lorn", "calder", "oxmoor"]

    @MainActor
    func compose(_ map: TableMap) -> PixelImage {
        var picture = PixelImage(width: map.width, height: map.height)
        if covered {
            picture.tableStamp(TableArt.pixels("tableCloth"), x: 0, y: 0)
            return picture
        }
        picture.tableStamp(TableArt.pixels("tableTop"), x: 0, y: 0)
        if west1 { picture.tableStamp(TableArt.pixels("tableWest1"), x: 0, y: 0) }
        if west2 { picture.tableStamp(TableArt.pixels("tableWest2"), x: 0, y: 0) }
        if span, let bridge = map.bridge {
            picture.tableStamp(TableArt.pixels("tableSpan"), x: bridge.x - 8, y: bridge.y - 4)
        }
        if let preview, let place = map.place(preview) {
            for (index, point) in place.road.enumerated() where index % 3 == 1 && point.x > map.planed + 1 {
                picture[point.x, point.y] = TableInk.strawLight
            }
        }
        for (id, fraction) in lines.sorted(by: { $0.key < $1.key }) {
            guard let place = map.place(id) else { continue }
            let lit = TableBoard.litRoad(place.road, fraction: fraction)
            for point in lit { picture[point.x, point.y] = TableInk.fireGold }
            if let head = lit.last { picture[head.x, head.y] = TableInk.fireWhite }
        }
        for place in map.pinned {
            guard let state = pins[place.id], let kind = TablePicture.pinKinds.firstIndex(of: place.pinKind) else {
                continue
            }
            let frame = TableArt.frame("tablePins", kind * 2 + (state == .lit ? 1 : 0), width: 9)
            picture.tableStamp(frame, x: place.pin.x - 4, y: place.pin.y - 4)
        }
        return picture
    }
}

/// The rail of the screen (128 x 30): the board with four hooks; a dark lantern on each hook at home, the reserved one
/// bound in red cloth, a lantern home with its report burning on its hook, a bare hook for a lantern out, soot and a
/// chalk stroke for a lost one, the blank lantern if Bram hung one; the number on each plate in the interface kit's
/// figures (5 x 7, advance 6), engraved in the brass.
enum TableRailPicture {
    static let width = 128
    static let height = 30
    /// The hooks' centres (x), left to right.
    static let slots = [16, 48, 80, 112]
    /// The lantern's frames in `tableRailLanterns` (9 x 13 each) and where its glass is lit (for the screen's glow).
    static let lanternWidth = 9
    static let lanternTop = 6
    static let glowY = 13

    static func frame(_ hook: TableBoard.Hook) -> Int? {
        switch hook {
        case .dark: return 0
        case .blank: return 1
        case .kept: return 2
        case .lit: return 3
        case .bare, .charred: return nil
        }
    }

    @MainActor
    static func compose(_ hooks: [(number: Int, hook: TableBoard.Hook)]) -> PixelImage {
        var picture = PixelImage(width: width, height: height)
        picture.tableStamp(TableArt.pixels("tableRail"), x: 0, y: 0)
        for (index, entry) in hooks.prefix(slots.count).enumerated() {
            let cx = slots[index]
            if entry.hook == .charred || entry.hook == .blank {
                picture.tableStamp(TableArt.pixels("tableSoot"), x: cx - 6, y: 3)
            }
            picture.tableStamp(TableArt.pixels("tableHook"), x: cx - 2, y: 0)
            if let frame = frame(entry.hook) {
                picture.tableStamp(TableArt.frame("tableRailLanterns", frame, width: lanternWidth), x: cx - 5,
                                   y: lanternTop)
            } else if entry.hook == .charred {
                picture.tableStamp(TableArt.pixels("tableChalk"), x: cx - 4, y: 10)
            }
            let digits = Array(String(entry.number)).compactMap { $0.wholeNumberValue }
            let start = cx - (digits.count * 6 - 1) / 2
            for (place, digit) in digits.enumerated() {
                picture.tableStamp(TableArt.frame("tableDigits", digit, width: 5), x: start + place * 6, y: 21)
            }
        }
        return picture
    }
}

/// A picture drawn at `unit` points per texel, never smoothed.
struct TablePixels: View {
    let image: CGImage?
    let unit: CGFloat

    var body: some View {
        if let image {
            Image(decorative: image, scale: 1)
                .resizable()
                .interpolation(.none)
                .frame(width: CGFloat(image.width) * unit, height: CGFloat(image.height) * unit)
        }
    }
}
