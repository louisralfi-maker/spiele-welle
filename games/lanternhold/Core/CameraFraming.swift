/// World rebuild, step world-3 (docs/REVIEW-look-2.md 2.7, DESIGN.md "World rebuild (14.11.2026)"): where the world's
/// camera aims. The scale stays an integer per device; only the camera's x changes.
///
/// - **Walking:** the camera follows the lord with 32 px of lead in his walking direction, eased in over half a second
///   once he walks (a critically damped ease, so it starts and ends without a jolt). The lead stays on his facing when
///   he stops, so a stop never makes the picture slide back; a jump (travel, a restart) clears it.
/// - **Set pieces:** at the beacon (470), the front gate (1360), the hall door (1830) and the back gate (2330), within
///   ±70 px of the anchor the goal is `anchor + (lord − anchor) × 0.3`, so the building stands centred and composed
///   while the lord moves within it. Beyond the reach the set piece lets go over a further 130 px (a smoothstep), so
///   the goal never jumps.
/// - **The danger:** at night in front of the castle, while creatures are on screen, the camera leads 60 px to the
///   left, toward the Gloom (eased in over about a second; it replaces the walking lead and the set piece).
/// - **Reduce Motion:** the lead, the danger lead and the set pieces are instant (no ease, no spring), as the follow
///   already is.
///
/// Picture only: nothing here reaches the simulation, the battle or the tuning (T1 to T8).
enum CameraFraming {
    /// The walking lead (game px) and the time it eases in over (s).
    static let walkLead = 32.0
    static let leadSeconds = 0.5
    /// The critically damped ease's rate: 95 % of the way in `leadSeconds` (4.74 / ω).
    static let leadOmega = 4.74 / 0.5
    /// The lead toward the danger at night (game px, to the left) and its ease (about 1.2 s to 95 %).
    static let dangerLead = 60.0
    static let dangerOmega = 4.0
    /// The four set pieces (world x): the beacon crag, the front gate, the hall door, the back gate.
    static let setPieces: [Double] = [WorldLayout.beaconX, 1360, SceneLayout.castleHallDoorX, WorldLayout.backGateX]
    /// Within this distance of an anchor the set piece holds fully; over `setPieceRelease` more it lets go.
    static let setPieceReach = 70.0
    static let setPieceRelease = 130.0
    /// How much of the lord's own move the camera takes inside a set piece.
    static let setPieceFollow = 0.3
    /// Creatures this far left of the screen's left edge already count as on screen (what the lead would show), so
    /// the danger lead never switches itself on and off at the edge.
    static let dangerMargin = 30.0

    /// What the camera needs of the world for one step.
    struct Input: Sendable, Equatable {
        var lordX: Double
        var velocity: Double
        var facing: Int
        /// 0 ... 1: how much the danger lead wants to be on (night at the front, creatures on screen).
        var danger: Double
    }

    /// The set piece the lord stands at and its hold on the camera (1 within the reach, 0 beyond the release).
    static func setPiece(lordX: Double) -> (anchor: Double, weight: Double)? {
        for anchor in setPieces {
            let distance = abs(lordX - anchor)
            guard distance < setPieceReach + setPieceRelease else { continue }
            let weight = 1 - AmbientRamp.smoothstep((distance - setPieceReach) / setPieceRelease)
            return (anchor, weight)
        }
        return nil
    }

    /// The camera's goal (the screen centre in world x) for the lord at `lordX` with the eased walking lead `lead`
    /// (signed game px) and the eased danger share `danger` (0 ... 1).
    static func goal(lordX: Double, lead: Double, danger: Double) -> Double {
        let share = min(1, max(0, danger))
        var focus = lordX + lead
        if let piece = setPiece(lordX: lordX) {
            let hold = piece.weight * (1 - share)
            let composed = piece.anchor + (lordX - piece.anchor) * setPieceFollow
            focus += (composed - focus) * hold
        }
        return focus + (lordX - dangerLead - focus) * share
    }

    /// How much of the night's front the camera is in (0 by day, eased in through the dusk and out through first
    /// light, fading out as the lord walks into the castle front). The danger lead needs creatures on screen as well.
    static func nightFront(_ state: GameState) -> Double {
        let hour = state.hour
        var night = 0.0
        if hour >= 19 && hour < 20 {
            night = hour - 19
        } else if hour >= 20 || hour < 5 {
            night = 1
        } else if hour >= 5 && hour < 6 {
            night = 6 - hour
        }
        let front = min(1, max(0, (WorldLayout.castleFrontX + 60 - state.king.x) / 120))
        return night * front
    }

    /// True while a creature stands in the view with its left edge at `left`, `width` game px wide (or just left of
    /// it, `dangerMargin`).
    static func creaturesOnScreen(_ state: GameState, left: Double, width: Double) -> Bool {
        let from = left - dangerMargin
        let to = left + width
        return state.creatures.contains { $0.x >= from && $0.x <= to }
    }

    /// The camera's input from the realm: the lord, and the danger lead's want for the view `camera` shows (none
    /// without a camera). `moving` false holds the lord still (a card is open).
    static func input(_ state: GameState, camera: Camera?, moving: Bool = true) -> Input {
        var danger = 0.0
        if let camera {
            let front = nightFront(state)
            if front > 0 && creaturesOnScreen(state, left: camera.x, width: camera.viewWidth) {
                danger = front
            }
        }
        return Input(lordX: state.king.x, velocity: moving ? state.king.velocity : 0, facing: state.king.facing,
                     danger: danger)
    }
}
