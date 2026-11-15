/// Build 3, POLISH pass 1 (docs/POLISH.md section 2; lane 3): what stands in look 2's scene to answer the wind. Its
/// frame comes from the wind in the picture alone (`WindLook`, `Weather.sailFrame`, `Weather.flagFrame`); nothing of
/// the simulation reads it. Art: tools/worldart.py `mill`, tools/bannerart.py `wind`.
extension SceneLayout {
    // MARK: The windmill at the valley's end (item 4)

    /// The windmill's left edge on the mid plane and its foot above the ground line: across the river behind the
    /// grove of the valley's tree belt (the belt, z 2, hides the tower's foot), its cap and sails above the trees
    /// against the hazy slopes. It shows from the river end (camera focus about 3480 to the world's end).
    static let look2WindmillX = 2096.0
    static let look2WindmillY = 14.0
    /// The sails' hub in the tower's sprite (from its left edge, rows up from its bottom row) and in the sails' cell.
    static let look2WindmillHub = (dx: 13.0, dy: 34.0)
    static let look2WindmillSailsHub = 23.0

    /// The tower, then its sails over it (the sails turn in front of the tower and its cap).
    static let look2Wind: [(plane: Plane, entry: Entry)] = [
        (.mid, Entry(sprite: .windmillTower, x: look2WindmillX, y: look2WindmillY, z: 1, region: .valley)),
        (.mid, Entry(sprite: .windmillSails, x: look2WindmillX + look2WindmillHub.dx - look2WindmillSailsHub,
                     y: look2WindmillY + look2WindmillHub.dy - look2WindmillSailsHub, z: 1, region: .valley)),
    ]
}
