/// Game mode's view of the M1b scene (M2b): the scene keeps the world (gorge, castle, valley, river, sky), but every
/// placeholder of something the simulation now owns gives way to what the realm really has. Hidden by sprite id and x:
/// the front's palisade, stone wall, their torch posts, the ballista and the two braziers (`SceneLayout`'s shot set),
/// the beacon ruin once a stage stands on it, the cottages and fields on the town plots. The hearth keeps its sprite
/// but loses its fire and light (the simulation's hearth burns by its strength), the scene's archers, creatures and
/// citizens leave, the king is the simulation's king, and the darkness bank stands at the simulation's edge. The
/// castle front's own wall-walk braziers, gate torches and lantern stay scenery. The light-probe mode
/// (`-GWScene probe`) draws the unfiltered scene.
enum SceneFilter {
    /// A placeholder of the scene: its sprite and left edge.
    struct Placeholder: Sendable, Equatable {
        let sprite: SpriteID
        let x: Double
    }

    /// The front of the M1b shots (`SceneLayout.makeWorld`): the outer line's palisade with its two torches and the
    /// ballista, the middle line's stone wall with its two torches and the braziers in front of it.
    static let frontPlaceholders: [Placeholder] = [
        Placeholder(sprite: .palisade, x: 640), Placeholder(sprite: .torchPost, x: 634),
        Placeholder(sprite: .torchPost, x: 662), Placeholder(sprite: .ballista, x: 676),
        Placeholder(sprite: .stoneWall, x: 940), Placeholder(sprite: .torchPost, x: 934),
        Placeholder(sprite: .torchPost, x: 978), Placeholder(sprite: .brazier, x: 891),
        Placeholder(sprite: .brazier, x: 915),
    ]

    /// What stands on the town plots in the scene.
    static let townSprites: Set<SpriteID> = [.house, .houseB, .houseC, .field]

    /// True for a scene prop that stands for something the simulation draws itself.
    static func isSimOwned(_ prop: Prop, beaconBuilt: Bool) -> Bool {
        guard prop.plane == .world else { return false }
        for entry in frontPlaceholders where entry.sprite == prop.sprite && abs(entry.x - prop.x) < 0.5 {
            return true
        }
        if prop.sprite == .beaconRuin { return beaconBuilt }
        if townSprites.contains(prop.sprite) {
            return WorldLayout.townPlots.contains { prop.x >= $0.start - 0.5 && prop.x < $0.end }
        }
        return false
    }

    /// True when the beacon's site holds a stage (finished or being raised over the cleared ruin).
    static func beaconBuilt(_ state: GameState) -> Bool {
        let site = state.plots[Realm.beaconPlot]
        return site.item != nil || site.job != nil
    }

    /// The scene as game mode draws it for `state`.
    static func gameScene(_ base: PlaceholderScene, state: GameState) -> PlaceholderScene {
        var scene = base
        let built = beaconBuilt(state)
        var props: [Prop] = []
        props.reserveCapacity(base.props.count)
        for prop in base.props {
            if isSimOwned(prop, beaconBuilt: built) { continue }
            if prop.sprite == .hearth && prop.plane == .world {
                var stripped = prop
                stripped.emissive = []
                stripped.lights = []
                props.append(stripped)
                continue
            }
            props.append(prop)
        }
        scene.props = props
        scene.actors = []
        scene.king = KingState(x: state.king.x, facing: state.king.facing, velocity: state.king.velocity)
        scene.bankRestingEdge = state.bankEdge
        scene.bankNightEdge = state.bankEdge
        return scene
    }

    /// The scene's own lights with their planes (windows, candles, the castle front's fires and lantern, the town's
    /// lanterns, the statue's bowl fire): every lit prop's lights, without the probe's lantern (the simulation's king
    /// carries his own, among the battle lights).
    static func sceneLights(_ scene: PlaceholderScene) -> [(source: LightSource, plane: Plane)] {
        var lights: [(source: LightSource, plane: Plane)] = []
        for prop in scene.props where prop.isLit {
            for light in prop.lights {
                lights.append((source: light, plane: prop.plane))
            }
        }
        return lights
    }
}
