/// Build 3, lane 5 step 2b (the smooth walk, the diagnosis's suspect 3): where look 2's emissive quads go.
///
/// The main emissive texture is read by the composite on the world plane's grid (its column and device shift). A glow
/// of a plane behind the lane (a window of the town's back row, the keep's panes, the valley keep's) or of the
/// foreground was read on that grid too, though its rect is in its own plane's pixels: against its wall it jumped by
/// the difference of the two planes' device shifts, up to 6 device px from one frame of a walk to the next. In look 2
/// these glows go into a texture of their own, one band per plane, and the composite reads each band at its own
/// plane's column and shift (`lh2_back_glow` in Shaders.metal), so a glow keeps its place on the sprite it lights in
/// every frame of a walk and of a pan. What stands in front of a band's plane hides it where that picture is opaque,
/// as the occluders did on the world's grid.
///
/// Occluders of a banded plane are drawn into their band (a sprite drawn later on the same plane hides the glow under
/// it) and, as before, into the main texture (the bloom's share of the lane's glows stays as it was). Look 1 keeps the
/// main texture for everything (its pictures are pinned by `LookGoldenTests`). The sky's quads go to the sky pass as
/// before.
enum EmissiveBands {
    /// The planes with a band, in band order.
    static let planes: [Plane] = [.far, .mid, .mistBand, .near, .foreground]
    /// The band of a glow of the near plane that lies over the lane (the far shore lantern's streak on the water, drawn
    /// after the lane's water so the water does not hide it): read at the near plane's column, hidden by nothing.
    static let overLane = 5
    /// Bands in the texture.
    static let count = 6
    /// Spare rows between two bands, so nothing read near a band's edge belongs to its neighbour.
    static let gap = 2

    /// Rows from one band's top to the next's.
    static func stride(targetHeight: Int) -> Int {
        max(1, targetHeight) + gap
    }

    /// The height of the band texture.
    static func textureRows(targetHeight: Int) -> Int {
        count * stride(targetHeight: targetHeight)
    }

    /// The band of an emissive of look 2, nil for the main texture (the world plane, the fog planes, the clouds) and
    /// for the sky (the sky pass).
    static func band(of emissive: EmissiveInstance) -> Int? {
        if emissive.plane == .near && emissive.sprite == .riverLanternStreak {
            return overLane
        }
        return planes.firstIndex(of: emissive.plane)
    }

    /// The plane at whose column and device shift the composite of look 2 reads an emissive's light.
    static func readPlane(of emissive: EmissiveInstance) -> Plane {
        if emissive.plane == .sky {
            return .sky
        }
        guard let band = band(of: emissive) else { return .world }
        return band == overLane ? .near : planes[band]
    }

    /// A quad of the band texture: its rect cut to the target's rows (so nothing spills into the next band), the atlas
    /// texels cut with it, then moved down to its band. Nil when nothing of it is on the target's rows.
    static func placed(_ quad: SpriteQuad, band: Int, targetHeight: Int) -> SpriteQuad? {
        let rows = Float(max(1, targetHeight))
        var rect = quad.rect
        var texel = quad.texel
        guard rect.w > 0 else { return nil }
        let above = max(0, -rect.y)
        let below = max(0, rect.y + rect.w - rows)
        guard above + below < rect.w else { return nil }
        let span = texel.w - texel.y
        texel.y += span * above / rect.w
        texel.w -= span * below / rect.w
        rect.y += above
        rect.w -= above + below
        rect.y += Float(band * stride(targetHeight: targetHeight))
        return SpriteQuad(rect: rect, texel: texel, tint: quad.tint)
    }
}
