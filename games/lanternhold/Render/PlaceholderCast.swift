import Foundation

/// Procedural stand-ins for the people lane's cast (docs/SPRITES-people.md, `PeopleCast`) when a PNG is missing: the
/// working people as the townsfolk, the children as the townsfolk cut to their frame, the nobles and the footman as
/// the envoy (the same canvas and frames); a cloth state as its body. The paintings of `Resources/Art` replace all of these.
enum PlaceholderCast {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        // a cloth state (docs/PEOPLE.md section 7) stands in as its body
        if let body = PeopleCast.body(dressedAs: sprite) { return PlaceholderArt.frames(for: body) }
        switch sprite {
        case .elder, .washerwoman, .labourer, .farmerHoe, .farmerScythe:
            let variant = sprite == .washerwoman ? 0 : (sprite == .labourer ? 1 : 2)
            return (0..<sprite.frameCount).map { PlaceholderPeople.townsfolk($0 % 6, variant: variant) }
        case .childA, .childB, .childC:
            let size = sprite.size
            return (0..<sprite.frameCount).map { frame in
                let full = PlaceholderPeople.townsfolk(frame % 6, variant: frame % 3)
                return full.cropped(x: (full.width - size.width) / 2, y: full.height - size.height,
                                    width: size.width, height: size.height)
            }
        case .nobleLord, .nobleLady, .footman:
            return PlaceholderCourt.frames(for: .envoy)
        default:
            return []
        }
    }
}
