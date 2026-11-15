import Foundation

/// Procedural stand-ins for the people lane's cast (docs/SPRITES-people.md, `PeopleCast`) when a PNG is missing: the
/// working people as the townsfolk, the children as the townsfolk cut to their frame, the nobles and the footman as
/// the envoy (the same canvas and frames); a cloth state as its body. The paintings of `Resources/Art` replace all of these.
enum PlaceholderCast {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        // a cloth state (docs/PEOPLE.md section 7) stands in as its body
        if let body = PeopleCast.body(dressedAs: sprite) { return PlaceholderArt.frames(for: body) }
        // a court member's tie stands in as the member's first frames (people-2 fix round 1, `CourtTies`)
        if let member = CourtTies.member(of: sprite) {
            return Array(PlaceholderArt.frames(for: member).prefix(CourtTies.frameCount))
        }
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
        case .lamplighter, .lamplighterGlow, .collector, .coach, .elderSeated:
            // people-2: the townsfolk's figure on the frame's canvas (bottom centre); the coach a plain block
            let size = sprite.size
            return (0..<sprite.frameCount).map { frame in
                var canvas = PixelImage(width: size.width, height: size.height)
                if sprite == .coach {
                    for y in 6..<size.height - 4 { for x in 4..<size.width - 4 { canvas[x, y] = RGBA(0x8E2B2A) } }
                    return canvas
                }
                let figure = PlaceholderPeople.townsfolk(frame % 6, variant: frame % 3)
                let fitted = figure.cropped(x: (figure.width - min(figure.width, size.width)) / 2,
                                            y: max(0, figure.height - size.height),
                                            width: min(figure.width, size.width), height: min(figure.height, size.height))
                canvas.copy(fitted, x: (size.width - fitted.width) / 2, y: size.height - fitted.height)
                return canvas
            }
        default:
            return []
        }
    }
}
