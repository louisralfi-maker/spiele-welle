/// The taxes on foot in the frame (town-2): `GameModel.frame` hands the entity layer here after the court's
/// (`CourtFrames.apply`), and `TownShow.scene` says what to add. Everything is added to the layer, nothing in the
/// simulation's drawing is changed but four things:
///
/// - over a house whose household stands in its door: the open door (`townCottage` / `townBigHouse` frame 0), and
///   after a knock the closed shutters (frame 1 ... 3), at the house's place and with its mirror, at z 0 after it;
/// - a house knocked at today keeps its window dark tonight: its lit rooms, glass masks and window lights go;
/// - the town's wanderers keep clear of every door where the taxes happen (`clearWanderers`, fix round 1);
/// - while the lord knocks or holds out his hand his sprite is his knock pose (`kingKnock` / `ladyKnock`, the same size
///   and anchor), his glow strip and his lantern's light stay on the lantern, which the pose keeps in place.
///
/// The households, the farmer and the coins they hold up stand before the lord; the coins in the air fly in front of
/// everyone. Every coin is an emissive actor with a small glow of its own pixels under it (fix round 1: the gold must
/// read at phone size), and the figures and coins stand on whole game pixels, the houses' grid, so the glow lies exactly
/// under its coin.
enum TownFrames {
    /// Prop ids of the town's overlays (above the entities' and the court's).
    static let propIDBase = 3_000_000
    /// The cottages' shade (as `EntityFrames.town` draws them), so an overlay matches its house pixel for pixel.
    static let cottageShade: Float = 0.97

    /// A coin's colour gain as an emissive actor (in flight and held), a held coin's while it glints, and the strength
    /// of the glow under it (× the fire's gold), in flight, held and glinting.
    static let coinTint: Float = 1.12
    static let glintTint: Float = 1.4
    static let flightGlow: Float = 1.5
    static let heldGlow: Float = 1.0
    static let glintGlow: Float = 2.2

    /// The wanderers (`EntityFrames.townsfolk`, the citizens' bodies) keep this far from a place where the taxes happen
    /// (game px): one whose walk would bring it nearer stops there and turns to watch; from `wanderFadeFrom` nearer it
    /// fades, and it is gone within `wanderGone`, so it reappears on the far side without a jump. Remove with the
    /// people lane's town life (docs/lanes/town.md, "the join").
    static let wanderClear = 32.0
    static let wanderFadeFrom = 20.0
    static let wanderGone = 10.0
    static let wanderers: Set<SpriteID> = [.citizen, .citizenB, .citizenC]
    /// The wanderers walk the town only: a place where the taxes happen west of this (the first morning's courtyard)
    /// moves nobody, so the court's people in townsfolk bodies (petitioners) are never touched.
    static var townWest: Double { (WorldLayout.townPlots.map(\.start).min() ?? 0) - wanderClear }

    // The collector is the people lane's Saul Bracken with his handcart (`TownLife.collector`, drawn with the town's
    // life in `EntityFrames`), placed by the town's round (`Town.collectorLeg`); the coins of the doors land in his
    // cart's strongbox at `TownShow.collectorBox` (the pre-join, 15.11.2026: the stand-in and its strongbox are gone).

    static func apply(_ layer: inout EntityLayer, state s: GameState, balance: Balance, view: EntityFrames.ActorView,
                      reduceMotion: Bool, refused: TownShow.Refused? = nil) {
        guard s.town != nil else { return }
        let scene = TownShow.scene(s, balance: balance, reduceMotion: reduceMotion, refused: refused)

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

        // The wanderers keep clear of the doors.
        clearWanderers(&layer, stages: scene.stages, view: view, time: s.simTime)

        // The figures and the coins they hold up, before the lord (and before whatever the court put before him).
        var figures: [ActorInstance] = []
        for figure in scene.figures where figure.alpha > 0.003 {
            let rect = view.rect(figure.sprite, x: figure.x.rounded(.down), y: 0)
            guard view.isOnScreen(rect) else { continue }
            figures.append(ActorInstance(sprite: figure.sprite, frame: figure.frame, rect: rect,
                                         tint: SIMD4<Float>(1, 1, 1, min(1, figure.alpha)), flipped: figure.flipped,
                                         isEmissive: false, isLit: true))
        }
        for coin in scene.held {
            let glint = coin.frame == TownSprites.CoinFrame.glint
            add(coin, tint: glint ? glintTint : coinTint, glow: glint ? glintGlow : heldGlow, view: view,
                actors: &figures, glows: &layer.glows)
        }
        let lordIndex = layer.actors.lastIndex { $0.sprite.isLord }
        if let lordIndex {
            layer.actors.insert(contentsOf: figures, at: lordIndex)
        } else {
            layer.actors += figures
        }

        // The lord's knock pose (the same size and anchor as his walking sprite). It keeps the standing frame's pole and
        // lantern, so his glow strip shows that frame and his lantern's light sits on the glass on the pose's side.
        if let pose = scene.lord, let index = layer.actors.lastIndex(where: { $0.sprite.isLord }) {
            let lord = s.lordOrDefault
            layer.actors[index].sprite = TownSprites.knock(lord)
            layer.actors[index].frame = pose.frame
            layer.actors[index].flipped = pose.flipped
            for strip in layer.actors.indices where layer.actors[strip].sprite == lord.glow {
                layer.actors[strip].frame = TownSprites.KnockFrame.lantern
                layer.actors[strip].flipped = pose.flipped
            }
            let facing: Double = pose.flipped ? -1 : 1
            // Only his own lantern: at his glass's height, as `EntityFrames` places it (a street lamp near a door
            // is never pulled onto him; fix round 2).
            for light in layer.lights.indices where layer.lights[light].source.kind == .lantern
                && layer.lights[light].source.y == EntityFrames.kingGlass.dy
                && abs(layer.lights[light].source.x - s.king.x) < EntityFrames.kingGlass.dx + 1 {
                layer.lights[light].source.x = s.king.x + EntityFrames.kingGlass.dx * facing
            }
        }

        // The coins in the air, in front of everyone.
        for coin in scene.coins {
            add(coin, tint: coinTint, glow: flightGlow, view: view, actors: &layer.actors, glows: &layer.glows)
        }
    }

    /// One coin: an emissive actor on whole game pixels (its centre at `coin.x`, `coin.y` above the ground) and a glow
    /// of its own pixels under it (the fire's gold × `glow`), which the bloom spreads a little.
    static func add(_ coin: TownShow.Coin, tint: Float, glow: Float, view: EntityFrames.ActorView,
                    actors: inout [ActorInstance], glows: inout [EntityGlow]) {
        guard coin.alpha > 0.003 else { return }
        let size = SpriteID.townCoin.size
        let left = (coin.x - Double(size.width) / 2).rounded(.down)
        let bottom = (coin.y - Double(size.height) / 2).rounded(.down)
        let rect = view.rect(.townCoin, x: left + Double(size.width / 2), y: bottom)
        guard view.isOnScreen(rect) else { return }
        let alpha = min(1, coin.alpha)
        actors.append(ActorInstance(sprite: .townCoin, frame: coin.frame, rect: rect,
                                    tint: SIMD4<Float>(tint, tint, tint, alpha), flipped: false, isEmissive: true,
                                    isLit: true))
        let gold = GamePalette.fireGold * glow
        glows.append(EntityGlow(.townCoin, x: left, y: bottom, color: SIMD4<Float>(gold.x, gold.y, gold.z, alpha),
                                frame: coin.frame))
    }

    /// The town's wanderers keep clear of every place in the town where the taxes happen now (`TownShow.Scene.stages`
    /// east of `townWest`): one within `wanderClear` of it stands at that distance on its own side, idle and facing
    /// it, fading from `wanderFadeFrom` nearer and gone within `wanderGone` (never pushed into another such place's
    /// room).
    static func clearWanderers(_ layer: inout EntityLayer, stages all: [Double], view: EntityFrames.ActorView,
                               time: Double) {
        let stages = all.filter { $0 >= townWest }
        guard !stages.isEmpty else { return }
        let scale = Float(max(1, view.scale))
        var gone: [Int] = []
        for index in layer.actors.indices where wanderers.contains(layer.actors[index].sprite) {
            var actor = layer.actors[index]
            var nearest: (stage: Double, dx: Double)?
            for stage in stages {
                let dx = Double((actor.rect.x - view.rect(actor.sprite, x: stage, y: 0).x) / scale)
                if abs(dx) < wanderClear && (nearest == nil || abs(dx) < abs(nearest!.dx)) { nearest = (stage, dx) }
            }
            guard let near = nearest else { continue }
            let side: Double = near.dx >= 0 ? 1 : -1
            var edge = near.stage + side * wanderClear
            for _ in 0..<stages.count {
                guard let other = stages.first(where: { abs(edge - $0) < wanderClear - 1e-6 }) else { break }
                edge = other + side * wanderClear
            }
            let alpha = Float(min(1, max(0, (abs(near.dx) - wanderGone) / (wanderFadeFrom - wanderGone))))
            guard alpha > 0.003 else {
                gone.append(index)
                continue
            }
            actor.rect.x = view.rect(actor.sprite, x: edge.rounded(.down), y: 0).x
            actor.frame = 4 + Int((max(0, time) * 2 + Double(index)).rounded(.down)) % 2
            actor.flipped = side > 0
            actor.tint.w = min(actor.tint.w, alpha)
            layer.actors[index] = actor
        }
        for index in gone.reversed() {
            layer.actors.remove(at: index)
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
