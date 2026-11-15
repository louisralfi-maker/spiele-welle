/// The parallax planes, back to front (DESIGN.md "Tech plan", docs/research-rendering.md 5.1). Each plane is one
/// low-resolution layer drawn at its own integer camera offset. `sky` holds the stars, the moon and the sun (fixed to
/// the screen), `clouds` the cloud bands (M1b, lit by the sky's own light). Look 2 adds two planes between the mid
/// plane and the play plane (DESIGN.md "Look 2 port"): `mistBand`, the painted mist between the distance and the near
/// trees, and `near`, the trees and crags close behind the lane. Look 1 leaves both empty and never draws them.
enum Plane: Int, Sendable, CaseIterable, Equatable, Comparable {
    case sky, clouds, far, mid, mistBand, near, fogA, world, fogB, foreground

    /// Parallax factor: how far the plane moves per game pixel of camera movement.
    var parallax: Double {
        switch self {
        case .sky: return 0
        case .clouds: return 0.05
        case .far: return 0.2
        case .mid: return 0.5
        case .mistBand: return 0.62
        case .near: return 0.75
        case .fogA: return 0.9
        case .world: return 1.0
        case .fogB: return 1.15
        case .foreground: return 1.3
        }
    }

    static func < (lhs: Plane, rhs: Plane) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How actors (king, people, creatures) are placed (`-GWActorMode`).
enum ActorMode: String, Sendable, CaseIterable, Equatable {
    /// Device-pixel precision in the composite (recommended: the walking king stays steady on screen).
    case smooth
    /// Snapped to whole game pixels of the world plane (for comparison).
    case snapped
}

/// One plane's camera offset (docs/research-rendering.md 3.2): `o = cameraX × p`, the low-resolution layer is drawn
/// at `whole = floor(o)`, and the composite shifts it left by `deviceShift = round(fraction × s)` device pixels. The
/// shift can equal `s`; the spare render-target column covers it.
struct PlaneOffset: Sendable, Equatable {
    let plane: Plane
    /// `o = cameraX × p` in game pixels.
    let offset: Double
    /// `n = floor(o)`.
    let whole: Int
    /// `f = o − n`, 0 ..< 1.
    let fraction: Double
    /// `round(f × s)` device pixels, 0 ... s.
    let deviceShift: Int

    init(plane: Plane, cameraX: Double, scale: Int) {
        let o = cameraX * plane.parallax
        let n = o.rounded(.down)
        let f = o - n
        let shift = f * Double(scale)
        self.plane = plane
        offset = o
        whole = Int(n)
        fraction = f
        deviceShift = Int(shift.rounded())
    }
}

/// The side-scrolling camera (DESIGN.md "Tech plan", docs/research-rendering.md 3.2).
///
/// `x` is the world x at the left edge of the screen (the scroll position), clamped so the view stays inside the
/// world 0 ... 3900 (`WorldLayout.width`). `focusX` is the screen centre, where the king stands (`-GWCameraX` sets
/// the focus).
///
/// Following uses a critically damped spring with the king's velocity fed forward. The spring aims at where the king
/// will be after the camera's own move (`goal - velocity * dt`), so while he walks at a steady speed the camera ends
/// each step centred on him (no lag and no lead, so he stays steady on screen); only when he starts or stops does he
/// drift a little off centre and the camera eases back. Reduce Motion: no lag, the camera sits on the king.
struct Camera: Sendable, Equatable {
    /// Spring stiffness of the follow (rad/s): settles in about a second.
    static let followOmega = 6.0

    /// World x at the left screen edge.
    private(set) var x: Double
    /// Camera speed in game px/s.
    private(set) var velocity: Double = 0
    /// Visible game columns (`PixelScale.visibleColumns`).
    let viewWidth: Double
    /// World width (game px).
    let worldWidth: Double
    /// World-3 (`CameraFraming`): the eased walking lead (signed game px) and its speed.
    private(set) var lead: Double = 0
    private(set) var leadVelocity: Double = 0
    /// World-3: the eased share of the danger lead (0 ... 1) and its speed.
    private(set) var danger: Double = 0
    private(set) var dangerVelocity: Double = 0
    /// World-3: the last framing goal (its change per step is fed forward to the follow); nil after a jump.
    private(set) var lastGoal: Double?

    /// A camera centred on `focusX`, clamped to the world.
    init(focusX: Double, viewWidth: Double, worldWidth: Double = WorldLayout.width) {
        self.viewWidth = max(1, viewWidth)
        self.worldWidth = worldWidth
        x = Camera.clampedLeft(focusX - max(1, viewWidth) / 2, viewWidth: max(1, viewWidth), worldWidth: worldWidth)
    }

    /// A camera centred on `focusX` for a pixel scale.
    init(focusX: Double, pixelScale: PixelScale, worldWidth: Double = WorldLayout.width) {
        self.init(focusX: focusX, viewWidth: pixelScale.visibleColumns, worldWidth: worldWidth)
    }

    /// The screen centre in world game pixels.
    var focusX: Double { x + viewWidth / 2 }

    /// The highest allowed left edge.
    var maxLeft: Double { max(0, worldWidth - viewWidth) }

    /// A left edge clamped so the view stays inside 0 ... worldWidth (pinned to 0 if the world is narrower).
    static func clampedLeft(_ left: Double, viewWidth: Double, worldWidth: Double) -> Double {
        let upper = max(0, worldWidth - viewWidth)
        return min(upper, max(0, left))
    }

    /// Jumps to a focus at once (debug arguments, travel); the camera stands still afterwards.
    mutating func jump(toFocus focus: Double) {
        x = Camera.clampedLeft(focus - viewWidth / 2, viewWidth: viewWidth, worldWidth: worldWidth)
        velocity = 0
    }

    /// One follow step of `dt` seconds toward the king at `targetX` moving at `targetVelocity` game px/s. Call it
    /// after the king has moved in the same step.
    mutating func follow(targetX: Double, targetVelocity: Double, dt: Double, reduceMotion: Bool = false) {
        let rawLeft = targetX - viewWidth / 2
        let goal = Camera.clampedLeft(rawLeft, viewWidth: viewWidth, worldWidth: worldWidth)
        let pinned = goal != rawLeft
        if reduceMotion {
            x = goal
            velocity = pinned ? 0 : targetVelocity
            return
        }
        let feedVelocity = pinned ? 0 : targetVelocity
        let omega = Camera.followOmega
        let spring = omega * omega * (goal - x - feedVelocity * dt)
        let damping = 2 * omega * (feedVelocity - velocity)
        velocity += (spring + damping) * dt
        x += velocity * dt
        if x < 0 {
            x = 0
            velocity = max(0, velocity)
        } else if x > maxLeft {
            x = maxLeft
            velocity = min(0, velocity)
        }
    }

    // MARK: World-3: the framing (REVIEW-look-2.md 2.7, `CameraFraming`)

    /// One step of the world's framing: eases the walking lead toward his facing once he walks, eases the danger
    /// lead toward its want, and follows the framing goal (the set pieces included) with its change fed forward, so
    /// a steady walk keeps the lord steady on screen. Reduce Motion: the leads and the goal are instant.
    mutating func frame(_ input: CameraFraming.Input, dt: Double, reduceMotion: Bool = false) {
        let step = max(0, dt)
        let walking = input.velocity != 0
        // The lead holds once he has walked: it turns with him, it stays when he stops.
        let leadTarget = walking || lead != 0 || leadVelocity != 0
            ? CameraFraming.walkLead * (input.facing < 0 ? -1 : 1) : 0
        let dangerTarget = min(1, max(0, input.danger))
        if reduceMotion {
            lead = leadTarget
            leadVelocity = 0
            danger = dangerTarget
            dangerVelocity = 0
        } else if step > 0 {
            Camera.ease(&lead, &leadVelocity, toward: leadTarget, omega: CameraFraming.leadOmega, dt: step)
            Camera.ease(&danger, &dangerVelocity, toward: dangerTarget, omega: CameraFraming.dangerOmega, dt: step)
            danger = min(1, max(0, danger))
        }
        let goal = CameraFraming.goal(lordX: input.lordX, lead: lead, danger: danger)
        var goalVelocity = input.velocity
        if let last = lastGoal, step > 0 {
            goalVelocity = (goal - last) / step
        }
        lastGoal = goal
        follow(targetX: goal, targetVelocity: goalVelocity, dt: step, reduceMotion: reduceMotion)
    }

    /// Cuts to the framing goal at once (a restart, travel): the walking lead is cleared, the danger share set to its
    /// want; the camera stands still afterwards.
    mutating func reframe(_ input: CameraFraming.Input) {
        lead = 0
        leadVelocity = 0
        danger = min(1, max(0, input.danger))
        dangerVelocity = 0
        let goal = CameraFraming.goal(lordX: input.lordX, lead: 0, danger: danger)
        jump(toFocus: goal)
        lastGoal = goal
    }

    /// A critically damped ease of `value` toward `target` (semi-implicit Euler, stable for ω·dt well under 1; the
    /// step is split when it is not).
    static func ease(_ value: inout Double, _ velocity: inout Double, toward target: Double, omega: Double,
                     dt: Double) {
        let pieces = max(1, Int((omega * dt / 0.25).rounded(.up)))
        let h = dt / Double(pieces)
        for _ in 0..<pieces {
            velocity += (omega * omega * (target - value) - 2 * omega * velocity) * h
            value += velocity * h
        }
        if abs(target - value) < 0.01 && abs(velocity) < 0.05 {
            value = target
            velocity = 0
        }
    }

    /// The camera offset of a plane.
    func offset(for plane: Plane, scale: Int) -> PlaneOffset {
        PlaneOffset(plane: plane, cameraX: x, scale: scale)
    }

    /// Every plane's offset, back to front.
    func offsets(scale: Int) -> [PlaneOffset] {
        Plane.allCases.map { offset(for: $0, scale: scale) }
    }

    /// The device-pixel x on screen of a point of the world plane at `worldX` (an actor's anchor).
    ///
    /// Smooth: `round((worldX − n) × s) − shift`, so the actor moves in steps of one device pixel and keeps a fixed
    /// screen position while the camera tracks it. Snapped: the actor sits on a whole world game pixel, like the world
    /// texture, and moves in steps of `s` device pixels.
    func deviceX(worldX: Double, scale: Int, mode: ActorMode) -> Int {
        let world = offset(for: .world, scale: scale)
        switch mode {
        case .smooth:
            let local = (worldX - Double(world.whole)) * Double(scale)
            return Int(local.rounded()) - world.deviceShift
        case .snapped:
            let snapped = Int(worldX.rounded())
            return (snapped - world.whole) * scale - world.deviceShift
        }
    }

    /// The king's on-screen x in device pixels (`debug-king-x`, the jitter test).
    func kingScreenX(kingX: Double, scale: Int, mode: ActorMode = .smooth) -> Int {
        deviceX(worldX: kingX, scale: scale, mode: mode)
    }

    /// Device-pixel y of the ground line on a bottom-anchored screen `physicalHeight` device pixels tall.
    static func groundDeviceY(physicalHeight: Int, scale: Int) -> Int {
        physicalHeight - WorldLayout.groundRowsBelow * scale
    }

    /// Render-target row of the ground line (objects standing on the ground end just above it).
    static func groundRow(targetHeight: Int) -> Int {
        targetHeight - WorldLayout.groundRowsBelow
    }
}
