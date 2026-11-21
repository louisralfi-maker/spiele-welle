/// Build 3, lane 5 step 2b (the smooth walk, the diagnosis's suspect 4): the pictures of look 2's props that move with
/// another plane than the one whose picture they stand in.
///
/// The keep stands in the near plane's picture but moves with the mist band; so do its flags, its vane and its
/// chimney's smoke. The keep's mist lies on fog A and moves with the mist band. Placed by the whole offset of the
/// plane they move with but shown at the device shift of the picture they were drawn into, they stepped against
/// their neighbours by up to 6 device px from one frame of a walk to the next (and now and then backward while
/// everything scrolled forward). In look 2 each goes into a picture of its own, read by the composite at the column
/// and device shift of the plane it moves with and lit as the picture it belonged to, at that picture's depth: just
/// behind it (no prop of that picture stands behind one of them on the screen: `SmoothWalkTests`). Look 1 keeps its
/// pictures (`LookGoldenTests`).
/// b3-smooth (build 3, lane 5b step 1, the critic's H2a): look 2 draws no valley keep (`SceneLayout.look2DroppedMid`
/// leaves out look 1's `keepFar` and its rock), so the valley's carried picture, always empty and still read for every
/// pixel, is gone with its band. Should a prop of the mid plane that moves with the far plane come back in look 2, it
/// needs a carried picture again (`SmoothWalkTests` asserts there is none).
enum CarriedPicture: Int, CaseIterable, Sendable {
    /// The keep, its flags, its vane, its smoke: lit as the near plane, between the mist band and the near plane.
    case keep
    /// The keep's mist: fog as fog A, between the near plane and fog A.
    case keepMist

    /// The plane whose picture the props belonged to (and whose light they take).
    var picture: Plane {
        switch self {
        case .keep: return .near
        case .keepMist: return .fogA
        }
    }

    /// The plane they move with: its whole offset places them, its device shift shows them.
    var motion: Plane {
        switch self {
        case .keep, .keepMist: return .mistBand
        }
    }

    /// The carried picture of a prop of `picture` that moves with `motion`, nil when it has none.
    static func of(picture: Plane, motion: Plane?) -> CarriedPicture? {
        guard let motion else { return nil }
        return allCases.first { $0.picture == picture && $0.motion == motion }
    }
}

extension FrameDesc {
    /// The sprites drawn into `plane`'s picture, with those of the carried pictures that belonged to it (their rects in
    /// the target pixels of the plane they move with, as before).
    func pictured(_ plane: Plane) -> [SpriteInstance] {
        var sprites = layer(plane).sprites
        for (index, picture) in carried.enumerated() where CarriedPicture(rawValue: index)?.picture == plane {
            sprites += picture.sprites
        }
        return sprites
    }

    /// The layer of a carried picture (empty when the frame has none: look 1, the hall).
    func carriedLayer(_ picture: CarriedPicture) -> PlaneLayer? {
        picture.rawValue < carried.count ? carried[picture.rawValue] : nil
    }
}
