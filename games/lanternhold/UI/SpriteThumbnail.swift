import CoreGraphics
import SwiftUI

/// The game's own pixel art on the cards (M2b part 2): a sprite cut from the atlas the renderer uses (the art lane's PNG
/// when the bundle has one, else the procedural placeholder), drawn with whole device pixels per art pixel where it
/// fits and never smoothed, on a small dusk tile in an inked frame.
@MainActor
enum SpriteImages {
    private static var cache: [String: CGImage] = [:]

    /// One frame of a sprite as a CGImage (straight alpha, sRGB), cached.
    static func image(_ sprite: SpriteID, frame: Int = 0) -> CGImage? {
        let key = "\(sprite.rawValue)#\(frame)"
        if let hit = cache[key] { return hit }
        let layout = AtlasLayout.shared
        let cell = layout.cell(sprite, frame: frame)
        let pixels = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
        guard let made = cgImage(pixels) else { return nil }
        cache[key] = made
        return made
    }

    static func cgImage(_ pixels: PixelImage) -> CGImage? {
        guard pixels.width > 0, pixels.height > 0, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let provider = CGDataProvider(data: Data(pixels.bytes) as CFData) else { return nil }
        return CGImage(width: pixels.width, height: pixels.height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: pixels.width * 4, space: space,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    /// The sprite a build item is drawn with.
    static func sprite(for item: BuildItem) -> SpriteID {
        switch item {
        case .gate: return .gateWood
        case .ironGate: return .gateIron
        case .greatGate: return .gateGreat
        case .palisade: return .palisade
        case .stoneWall: return .stoneWall
        case .bastion: return .bastion
        case .archerTower: return .archerTower
        case .watchtower: return .watchtower
        case .brazier: return .brazier
        case .fireTower: return .fireTower
        case .ballista: return .ballista
        case .catapult: return .catapult
        case .stakePit: return .stakePit
        case .beaconBase: return .beaconBase
        case .beaconTower: return .beaconTower
        case .greatBeacon: return .greatBeacon
        case .smithy: return .smithy
        case .masterSmithy: return .masterSmithy
        case .lodge: return .lodge
        case .bigLodge: return .bigLodge
        case .house: return .house
        case .bigHouse: return .bigHouse
        case .field: return .field
        case .market: return .market
        case .tavern: return .tavern
        }
    }

    static func sprite(for kind: SoldierKind) -> SpriteID {
        kind == .archer ? .archer : .guardsman
    }
}

/// A sprite on a small framed tile, `side` points square.
struct SpriteThumbnail: View {
    let sprite: SpriteID
    var side: CGFloat = 46
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let size = sprite.size
        let inner = side - 8
        let devicePixels = inner * displayScale
        let largest = CGFloat(max(1, max(size.width, size.height)))
        // Whole device pixels per art pixel when the sprite fits at one or more; else scaled down to fit.
        let whole = (devicePixels / largest).rounded(.down)
        let scale = whole >= 1 ? whole / displayScale : inner / largest
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x3B3566), Color(hex: 0x6E5A7E), Color(hex: 0xC98A6A)],
                                     startPoint: .top, endPoint: .bottom))
            if let image = SpriteImages.image(sprite) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: CGFloat(size.width) * scale, height: CGFloat(size.height) * scale)
                    .frame(width: inner, height: inner, alignment: .bottom)
            }
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(Theme.ink, lineWidth: 1.5)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}
