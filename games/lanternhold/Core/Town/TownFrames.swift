/// The taxes on foot in the frame (town-2): `GameModel.frame` hands the entity layer here after the court's
/// (`CourtFrames.apply`), and `TownShow.scene` says what to add. Everything is added to the layer, nothing in the
/// simulation's drawing is changed but three things of the houses:
///
/// - over a house whose household stands in its door: the open door (`townCottage` / `townBigHouse` frame 0), and
///   after a knock the closed shutters (frame 1 ... 3), at the house's place and with its mirror, at z 0 after it;
/// - a house knocked at today keeps its window dark tonight: its lit rooms, glass masks and window lights go;
/// - the households and the farmer stand before the lord, the coins fly in front of everyone, and while the lord
///   knocks or holds out his hand his sprite is his knock pose (`kingKnock` / `ladyKnock`, the same size and anchor).
enum TownFrames {
    /// Prop ids of the town's overlays (above the entities' and the court's).
    static let propIDBase = 3_000_000
    /// The cottages' shade (as `EntityFrames.town` draws them), so an overlay matches its house pixel for pixel.
    static let cottageShade: Float = 0.97

    static func apply(_ layer: inout EntityLayer, state s: GameState, balance: Balance, view: EntityFrames.ActorView,
                      reduceMotion: Bool, refused: TownShow.Refused? = nil) {
        guard s.town != nil else { return }
        let scene = TownShow.scene(s, balance: balance, reduceMotion: reduceMotion, refused: refused)
        let isDay = DayClock.phase(at: s.hour) == .day

        // The houses.
        var count = 0
        for house in scene.houses {
            if house.dark { darken(&layer, house: house) }
            let shade: Float = house.overlay == .townCottage ? cottageShade : 1
            if house.doorOpen {
                layer.props.append(Prop(id: propIDBase + count, sprite: house.overlay, plane: .world, x: house.left,
                                        y: 0, z: 0, shade: shade, flipped: house.mirrored,
                                        region: WorldLayout.worldRegion(x: house.left),
                                        frame: TownSprites.OverlayFrame.door))
                count += 1
            }
            if house.shutters {
                let frame = house.overlay == .townCottage ? house.shutterFrame : TownSprites.OverlayFrame.shutters
                layer.props.append(Prop(id: propIDBase + count, sprite: house.overlay, plane: .world, x: house.left,
                                        y: 0, z: 0, shade: shade, flipped: house.mirrored,
                                        region: WorldLayout.worldRegion(x: house.left), frame: frame))
                count += 1
            }
        }

        // The figures, before the lord (and before whatever the court put before him).
        var figures: [ActorInstance] = []
        for figure in scene.figures where isDay || figure.alpha > 0 {
            let rect = view.rect(figure.sprite, x: figure.x, y: 0)
            guard view.isOnScreen(rect), figure.alpha > 0.003 else { continue }
            figures.append(ActorInstance(sprite: figure.sprite, frame: figure.frame, rect: rect,
                                         tint: SIMD4<Float>(1, 1, 1, min(1, figure.alpha)), flipped: figure.flipped,
                                         isEmissive: false, isLit: true))
        }
        let lordIndex = layer.actors.lastIndex { $0.sprite.isLord }
        if let lordIndex {
            layer.actors.insert(contentsOf: figures, at: lordIndex)
        } else {
            layer.actors += figures
        }

        // The lord's knock pose (the same size and anchor as his walking sprite).
        if let pose = scene.lord, let index = layer.actors.lastIndex(where: { $0.sprite.isLord }) {
            layer.actors[index].sprite = TownSprites.knock(s.lordOrDefault)
            layer.actors[index].frame = pose.frame
            layer.actors[index].flipped = pose.flipped
            let glow = s.lordOrDefault.glow
            layer.actors.removeAll { $0.sprite == glow }
        }

        // The coins, in front of everyone.
        let half = Double(SpriteID.townCoin.size.height) / 2
        for coin in scene.coins where coin.alpha > 0.003 {
            let rect = view.rect(.townCoin, x: coin.x, y: coin.y - half)
            guard view.isOnScreen(rect) else { continue }
            layer.actors.append(ActorInstance(sprite: .townCoin, frame: coin.frame, rect: rect,
                                              tint: SIMD4<Float>(1, 1, 1, min(1, coin.alpha)), flipped: false,
                                              isEmissive: false, isLit: true))
        }
    }

    /// A house knocked at today: no lit room, no glass glow and no window light tonight.
    static func darken(_ layer: inout EntityLayer, house: TownShow.House) {
        let houses: Set<SpriteID> = [.house, .houseB, .houseC, .bigHouse]
        let width = Double(house.overlay.size.width)
        for index in layer.props.indices where houses.contains(layer.props[index].sprite)
            && abs(layer.props[index].x - house.left) < 0.5 {
            layer.props[index].emissive = []
            layer.props[index].masks = []
        }
        layer.lights.removeAll { light in
            light.source.kind == .window && light.source.x >= house.left - 0.5
                && light.source.x <= house.left + width + 0.5
        }
    }
}
