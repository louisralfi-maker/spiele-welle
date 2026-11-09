import CoreGraphics
import SwiftUI

/// The audience card's portraits (M3 step 3): a story character's own portrait cut from the atlas (Seren's hooded or
/// revealed frame), a townsfolk petitioner's composed from the contract's parts with its swap ramps
/// (`PortraitComposer`, from the atlas, so the art lane's PNGs show by themselves), cached.
@MainActor
enum PortraitImages {
    private static var cache: [String: CGImage] = [:]

    static func image(_ portrait: AudienceCard.Portrait) -> CGImage? {
        switch portrait {
        case .own(let sprite, let frame):
            return SpriteImages.image(sprite, frame: frame)
        case .composed(let recipe):
            let key = "\(recipe.clothes)-\(recipe.face)-\(recipe.beard)-\(recipe.hair)-\(recipe.hat)-"
                + "\(recipe.skin.rawValue)-\(recipe.hairColor.rawValue)-\(recipe.cloth.rawValue)"
            if let hit = cache[key] { return hit }
            guard let made = SpriteImages.cgImage(PortraitComposer.compose(recipe, atlas: .shared)) else { return nil }
            cache[key] = made
            return made
        }
    }
}

/// A 48x48 portrait on a framed dusk tile, drawn with whole device pixels per art pixel (never smoothed).
struct PortraitTile: View {
    let portrait: AudienceCard.Portrait
    var side: CGFloat = 72
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let art = CGFloat(SpriteID.portraitFace.size.width)
        let inner = side - 8
        let whole = max(1, (inner * displayScale / art).rounded(.down))
        let points = art * whole / displayScale
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x3B3566), Color(hex: 0x6E5A7E), Color(hex: 0xC98A6A)],
                                     startPoint: .top, endPoint: .bottom))
            if let image = PortraitImages.image(portrait) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: points, height: points)
                    .frame(width: inner, height: inner, alignment: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Theme.woodDark, lineWidth: 2)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .inset(by: 2.5)
                .strokeBorder(Theme.goldDeep.opacity(0.65), lineWidth: 1)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}
