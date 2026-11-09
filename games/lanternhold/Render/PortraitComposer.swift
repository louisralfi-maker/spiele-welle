/// Composes a townsfolk portrait (SPRITES.md "M3"): the parts drawn in order on one head template (clothes, face,
/// beard, hair, hat; the "none" frames skipped), each swap ramp mapped colour for colour to the petitioner's target
/// ramp. The audience card shows the result; the placeholders compose the story portraits the same way.
enum PortraitComposer {
    /// The image with every colour of each `from` ramp replaced by the colour at the same step of its `to` ramp.
    static func swapped(_ image: PixelImage, ramps: [(from: [UInt32], to: [UInt32])]) -> PixelImage {
        var map: [RGBA: RGBA] = [:]
        for ramp in ramps {
            for (index, from) in ramp.from.enumerated() where index < ramp.to.count {
                map[RGBA(from)] = RGBA(ramp.to[index])
            }
        }
        guard !map.isEmpty else { return image }
        var out = image
        for y in 0..<image.height {
            for x in 0..<image.width {
                let texel = image[x, y]
                guard texel.a > 0, let target = map[texel.alpha(255)] else { continue }
                out[x, y] = target.alpha(texel.a)
            }
        }
        return out
    }

    /// Draws `layer` over `base`, texel for texel where the layer is opaque.
    static func over(_ base: PixelImage, _ layer: PixelImage) -> PixelImage {
        var out = base
        for y in 0..<min(base.height, layer.height) {
            for x in 0..<min(base.width, layer.width) {
                let texel = layer[x, y]
                if texel.a >= 128 { out[x, y] = texel }
            }
        }
        return out
    }

    /// The portrait of `recipe` from a source of part frames (the atlas, or the placeholders).
    static func compose(_ recipe: PortraitRecipe, part: (SpriteID, Int) -> PixelImage) -> PixelImage {
        let size = SpriteID.portraitFace.size
        var image = PixelImage(width: size.width, height: size.height)
        let ramps: [(from: [UInt32], to: [UInt32])] = [
            (PortraitRamps.skin, recipe.skin.ramp), (PortraitRamps.hair, recipe.hairColor.ramp),
            (PortraitRamps.cloth, recipe.cloth.ramp),
        ]
        for layer in recipe.layers {
            image = over(image, swapped(part(layer.sprite, layer.frame), ramps: ramps))
        }
        return image
    }

    /// The portrait of `recipe` cut from the atlas page (the art lane's PNGs once they land).
    static func compose(_ recipe: PortraitRecipe, atlas: AtlasLayout) -> PixelImage {
        compose(recipe) { sprite, frame in
            let cell = atlas.cell(sprite, frame: frame)
            return atlas.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
        }
    }
}
