import Foundation

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
///
/// Build 3, lane 5 (the look-around, `LookAround`): `pan` slides the view from where the follow holds it (`baseX`),
/// kept inside the world; `x`, and with it every plane, actor and touch, shows the slid view. Without a pan `x` is
/// `baseX`.
struct Camera: Sendable, Equatable {
    /// Spring stiffness of the follow (rad/s): settles in about a second.
    static let followOmega = 6.0

    /// World x at the left screen edge: the follow's edge slid by the look-around's pan, inside the world.
    var x: Double {
        pan == 0 ? baseX : Camera.clampedLeft(baseX + pan, viewWidth: viewWidth, worldWidth: worldWidth)
    }
    /// The follow's own left edge (without the look-around's pan).
    private(set) var baseX: Double
    /// Build 3, lane 5: how far the look-around slides the view from `baseX` (game px, + east); 0 everywhere else.
    private(set) var pan: Double = 0
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
    // LANE-A: A1
    /// Polish step A1 (the gate, A1-C1): the goal's velocity fed forward in the last follow step, so a goal that stops
    /// from pace in one step (a drag let go, the hall's walker) is told from one that braked onto its spot.
    private(set) var lastFeed: Double = 0
    // LANE-A end

    /// A camera centred on `focusX`, clamped to the world.
    init(focusX: Double, viewWidth: Double, worldWidth: Double = WorldLayout.width) {
        self.viewWidth = max(1, viewWidth)
        self.worldWidth = worldWidth
        baseX = Camera.clampedLeft(focusX - max(1, viewWidth) / 2, viewWidth: max(1, viewWidth),
                                   worldWidth: worldWidth)
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

    /// Jumps to a focus at once (debug arguments, travel); the camera stands still afterwards. With a look-around pan
    /// the slid view lands on the focus (the frame's shake moves the slid view).
    mutating func jump(toFocus focus: Double) {
        baseX = Camera.clampedLeft(focus - viewWidth / 2 - pan, viewWidth: viewWidth, worldWidth: worldWidth)
        velocity = 0
    }

    // MARK: Build 3, lane 5: the look-around's pan

    /// The pans that keep the view inside the world from where the follow holds it.
    var panRange: ClosedRange<Double> {
        let low = -baseX
        return low...max(low, maxLeft - baseX)
    }

    /// Slides the view `value` game px from where the follow holds it (+ east), kept inside the world.
    mutating func setPan(_ value: Double) {
        let range = panRange
        pan = min(range.upperBound, max(range.lowerBound, value))
    }

    /// One follow step of `dt` seconds toward the king at `targetX` moving at `targetVelocity` game px/s. Call it
    /// after the king has moved in the same step.
    mutating func follow(targetX: Double, targetVelocity: Double, dt: Double, reduceMotion: Bool = false) {
        let rawLeft = targetX - viewWidth / 2
        let goal = Camera.clampedLeft(rawLeft, viewWidth: viewWidth, worldWidth: worldWidth)
        let pinned = goal != rawLeft
        if reduceMotion {
            baseX = goal
            velocity = pinned ? 0 : targetVelocity
            return
        }
        let feedVelocity = pinned ? 0 : targetVelocity
        let omega = Camera.followOmega
        let spring = omega * omega * (goal - baseX - feedVelocity * dt)
        let damping = 2 * omega * (feedVelocity - velocity)
        // LANE-A: A1
        let behind = goal - baseX
        // LANE-A end
        velocity += (spring + damping) * dt
        baseX += velocity * dt
        // LANE-A: A1
        // Polish step A1 (the walk's start and brake): the follow never runs past a goal that stands or moves on the
        // same way, so a stop never slides the picture back (the spring's overshoot was about 1.7 game px after
        // every stop). A goal that comes toward the camera (a turn) is followed back as before. A goal that stopped
        // dead from pace in this step (`FigureMotion.cameraDeadStopSpeed`) is eased past and back as before, so the
        // picture never stops in one frame (the gate, A1-C1).
        let ahead = goal - baseX
        let stoppedDead = feedVelocity == 0 && abs(lastFeed) > FigureMotion.cameraDeadStopSpeed
        if !stoppedDead
            && ((behind != 0 && ahead * behind < 0 && feedVelocity * behind >= 0)
                || (behind == 0 && feedVelocity == 0 && ahead != 0)) {
            baseX = goal
            velocity = feedVelocity
        }
        lastFeed = feedVelocity
        // LANE-A end
        if baseX < 0 {
            baseX = 0
            velocity = max(0, velocity)
        } else if baseX > maxLeft {
            baseX = maxLeft
            velocity = min(0, velocity)
        }
    }

    // MARK: World-3: the framing (REVIEW-look-2.md 2.7, `CameraFraming`)

    /// One step of the world's framing: eases the walking lead toward his facing once he walks, eases the danger
    /// lead toward its want, and follows the framing goal (the set pieces included) with its change fed forward, so
    /// a steady walk keeps the lord steady on screen. Reduce Motion: the leads and the goal are instant.
    mutating func frame(_ input: CameraFraming.Input, dt: Double, reduceMotion: Bool = false) {
        // Build 3, lane 5: while the look-around slides the view and the lord stands, the follow holds still, so the
        // realm stays under the finger (the danger lead would ease in as creatures come into the slid view).
        if pan != 0 && input.velocity == 0 { return }
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
            var value = lead
            var speed = leadVelocity
            Camera.ease(&value, &speed, toward: leadTarget, omega: CameraFraming.leadOmega, dt: step)
            lead = value
            leadVelocity = speed
            value = danger
            speed = dangerVelocity
            Camera.ease(&value, &speed, toward: dangerTarget, omega: CameraFraming.dangerOmega, dt: step)
            danger = min(1, max(0, value))
            dangerVelocity = speed
        }
        let goal = CameraFraming.goal(lordX: input.lordX, lead: lead, danger: danger)
        var goalVelocity = input.velocity
        if let last = lastGoal, step > 0 {
            goalVelocity = (goal - last) / step
        }
        lastGoal = goal
        follow(targetX: goal, targetVelocity: goalVelocity, dt: step, reduceMotion: reduceMotion)
    }

    /// World-3 fix round 1 (`-GWWalk`, the sweep's proof): the walking lead as it stands after half a second of walking
    /// toward `facing`, and the camera on its goal.
    mutating func presetLead(facing: Int, lordX: Double) {
        lead = CameraFraming.walkLead * (facing < 0 ? -1 : 1)
        leadVelocity = 0
        let goal = CameraFraming.goal(lordX: lordX, lead: lead, danger: danger)
        jump(toFocus: goal)
        lastGoal = goal
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

/// Build 3, lane 5 (docs/HUD.md section 2; DIRECTOR.md, the director's ideas for build 3: the look-around): with the
/// lantern up and the world still, a sideways drag slides the realm under the finger, one to one; letting go glides the
/// view home to the lord, an ease-out of `glideSeconds` (Reduce Motion: home at once). `pan` is how far the view stands
/// slid (game px, + east); the camera keeps it inside the world (`Camera.setPan`). Picture only, never saved.
struct LookAround: Sendable, Equatable {
    /// The glide home's length (s).
    static let glideSeconds = 0.35

    /// How far the view stands slid from the lord's view (game px, + east).
    private(set) var pan: Double = 0
    /// While a finger holds the view: its sideways travel (game px, + right) at the last step.
    private(set) var finger: Double?
    /// The glide home: the pan it set off from and its seconds so far.
    private(set) var glideFrom: Double?
    private(set) var glideTime = 0.0
    /// The Debug pictures (`-GWLookAround <dx>:<slow>`): the glide home takes this many times its length.
    var glideScale = 1.0

    /// A finger holds the view.
    var isHeld: Bool { finger != nil }
    /// The view glides home.
    var isGliding: Bool { glideFrom != nil }

    /// A finger takes the view, its sideways travel at `travel` game px when the drag began: a glide stops where it is.
    mutating func grab(travel: Double) {
        finger = travel
        glideFrom = nil
        glideTime = 0
    }

    /// The finger travelled to `travel` game px (+ right): the view slides by the same amount the other way, so the
    /// realm moves with the finger, kept inside `range`; at an end the view waits and turns back with the finger at once.
    mutating func drag(travel: Double, range: ClosedRange<Double>) {
        guard let last = finger else { return }
        finger = travel
        pan = min(range.upperBound, max(range.lowerBound, pan - (travel - last)))
    }

    /// The view stands at `value` at once, inside `range`, held by no finger (the Debug pictures).
    mutating func place(_ value: Double, range: ClosedRange<Double>) {
        pan = min(range.upperBound, max(range.lowerBound, value))
        finger = nil
        glideFrom = nil
        glideTime = 0
    }

    /// The finger lets go, or the lantern goes down: the view glides home; with Reduce Motion it is home at once.
    mutating func release(reduceMotion: Bool) {
        finger = nil
        guard pan != 0, !reduceMotion else {
            home()
            return
        }
        glideFrom = pan
        glideTime = 0
    }

    /// The view is home at once (under a card, out of the world).
    mutating func home() {
        pan = 0
        finger = nil
        glideFrom = nil
        glideTime = 0
    }

    /// One step of real time: the glide home goes on.
    mutating func step(_ seconds: Double) {
        guard let from = glideFrom else { return }
        glideTime += max(0, seconds)
        let t = min(1, glideTime / (LookAround.glideSeconds * max(1, glideScale)))
        pan = from * LookAround.remaining(t)
        if t >= 1 { home() }
    }

    /// The share of the pan still to go at `t` (0 ... 1) of the glide: a cubic ease-out, quick at first, settling soft.
    static func remaining(_ t: Double) -> Double {
        let left = 1 - min(1, max(0, t))
        return left * left * left
    }
}

/// `-GWLookAround <dx>[:<slow>]` (build 3, lane 5; the look-around's pictures, read only in a Debug build): each time
/// the lantern moment opens on the world the view stands slid `dx` game px east (0: not slid), and the glide home takes
/// `slow` times its length (1 ... 40), so a strip of frames can follow it. `dx` may start with `e` (east) or `w` (west):
/// a launch argument that starts with a minus could be read as a key, so `w2000` slides 2000 px west. Step 5: a third
/// part `hold<s>` (0.5 ... 30) has a finger hold the slid view for that many seconds of real time before it lets go,
/// so the look-around's clean frame can be pictured (`e99999:4:hold4`).
struct LookAroundDebug: Sendable, Equatable {
    var pan: Double
    var slow: Double
    var hold: Double? = nil

    static func parse(_ text: String?) -> LookAroundDebug? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        var head = parts[0]
        var sign = 1.0
        if head.hasPrefix("w") {
            sign = -1
            head = String(head.dropFirst())
        } else if head.hasPrefix("e") {
            head = String(head.dropFirst())
        }
        guard let pan = Double(head), pan.isFinite else { return nil }
        var slow = 1.0
        if parts.count > 1 {
            guard let value = Double(parts[1]), value.isFinite else { return nil }
            slow = min(40, max(1, value))
        }
        var hold: Double?
        if parts.count > 2 {
            guard parts[2].hasPrefix("hold"), let value = Double(parts[2].dropFirst(4)), value.isFinite else {
                return nil
            }
            hold = min(30, max(0.5, value))
        }
        return LookAroundDebug(pan: sign * pan, slow: slow, hold: hold)
    }
}
