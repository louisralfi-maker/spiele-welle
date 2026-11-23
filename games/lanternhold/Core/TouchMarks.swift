import Foundation

/// How a stage lies on the screen (stage lane, step stage-2): device px of the drawable against game px of the stage
/// (the world strip, or the great hall at its walking or audience framing). The touches go one way (a finger's point
/// to the stage's x and the height above the walk line), the marks, the slip and the accessibility elements the other.
struct TouchFraming: Sendable, Equatable {
    var stage: StageKind
    /// The world plane's offset: its whole part and the device px of its fraction (`PlaneOffset`).
    var whole: Double
    var deviceShift: Double
    /// Device px per game px (fractional while the hall eases into the audience framing).
    var scale: Double
    /// The walk line's device y.
    var groundY: Double
    var physicalWidth: Double
    var physicalHeight: Double

    func stageX(deviceX: Double) -> Double { whole + (deviceX + deviceShift) / max(0.01, scale) }
    func lift(deviceY: Double) -> Double { (groundY - deviceY) / max(0.01, scale) }
    func deviceX(stageX: Double) -> Double { ((stageX - whole) * scale).rounded() - deviceShift }
    func deviceY(lift: Double) -> Double { (groundY - lift * scale).rounded() }

    var viewLeft: Double { stageX(deviceX: 0) }
    var viewRight: Double { stageX(deviceX: physicalWidth) }

    /// The world strip under `camera` (the actors' smooth placement, `Camera.deviceX`).
    static func world(camera: Camera, pixelScale: PixelScale) -> TouchFraming {
        let offset = camera.offset(for: .world, scale: pixelScale.scale)
        return TouchFraming(stage: .world, whole: Double(offset.whole), deviceShift: Double(offset.deviceShift),
                            scale: Double(pixelScale.scale),
                            groundY: Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                                 scale: pixelScale.scale)),
                            physicalWidth: Double(pixelScale.physicalWidth),
                            physicalHeight: Double(pixelScale.physicalHeight))
    }

    /// The great hall at its framing now (`HallFraming.framing`: the walking camera's left edge and the move into the
    /// audience framing), placed as `HallFrames` places its actors.
    static func hall(pixelScale: PixelScale, walkLeft: Double, progress: Double) -> TouchFraming {
        let framing = HallFraming.framing(pixelScale, walkLeft: walkLeft, progress: progress)
        let offset = PlaneOffset(plane: .world, offset: framing.left, zoom: framing.scale)
        let ground = Double(pixelScale.physicalHeight) - Double(WorldLayout.groundRowsBelow) * framing.scale
        return TouchFraming(stage: .hall, whole: Double(offset.whole), deviceShift: Double(offset.deviceShift),
                            scale: framing.scale, groundY: ground, physicalWidth: Double(pixelScale.physicalWidth),
                            physicalHeight: Double(pixelScale.physicalHeight))
    }
}

/// One mark to draw: its tag, where its tip stands, idle or pressed, and its pool's place at the thing's feet.
struct TouchMark: Sendable, Equatable {
    var sprite: SpriteID
    var x: Double
    var lift: Double
    var pressed: Bool
    var poolX: Double
    /// Fix round 1: what it marks, for the gold rim on the thing (its kind, who speaks there, its half width), and an
    /// empty plot's footing (its half width; nil: none).
    var kind: TouchKind = .plot
    var who: String? = nil
    var half: Double = 6
    var footing: Double? = nil
    var rimX: Double? = nil
    /// Stage-3-interface (stage-2 critic look 2, high 2): something else stands for the thing now (its count's board, a
    /// board before a person, the horn's slip at the hall's door), so the tag is not drawn (its rim and pool stay).
    /// Polish B3: the errand slip is gone; the errand's own mark is its sign (pressed, never hidden).
    var hidden = false
    /// Polish B3 (one presence, law 1 quick): the thing's id (the key its presence is kept by), the mark's share while
    /// it comes or goes (tag, pool, rim and footing alike), the whole game px it stands below its place while it comes
    /// (2, 1, 0; none under Reduce Motion), and the tag's own share while it gives way to a board or comes back.
    var id = ""
    var alpha = 1.0
    var rise = 0
    var tagAlpha = 1.0

    /// The tag's share on screen.
    var tagShare: Double { alpha * tagAlpha }
}

/// The marks of touch the world on a stage (SPRITES.md "The marks of 'touch the world'"): a small tag over each thing
/// that offers something, at most four in view, the nearest to the lord first (`TouchRules.marked`); drawn unlit, at
/// night at three quarters of its value and warmed (M11); frame 1 while the finger is down on it. A pool of warm light
/// at the thing's feet (radius 20, 0.7; 1.4 times that while pressed), a scene light that only shows after dusk. Nothing
/// bobs or blinks.
enum TouchMarks {
    /// The marks of `marked` (already chosen and in order), with the one under the finger pressed.
    static func marks(_ marked: [TouchThing], pressed: String?) -> [TouchMark] {
        marked.compactMap { thing in
            guard let sprite = thing.kind.mark else { return nil }
            return TouchMark(sprite: sprite, x: thing.markX, lift: thing.markLift, pressed: thing.id == pressed,
                             poolX: thing.x, kind: thing.kind, who: thing.who, half: thing.halfWidth,
                             footing: thing.footing, rimX: thing.rimX, id: thing.id)
        }
    }

    /// The device rect of a mark: its tip (frame x 7, its bottom row) over `x`, at `lift` above the walk line.
    static func rect(_ mark: TouchMark, framing: TouchFraming) -> SIMD4<Float> {
        let size = mark.sprite.size
        let anchor = framing.deviceX(stageX: mark.x)
        let width = Double(size.width) * framing.scale
        let height = Double(size.height) * framing.scale
        let left = anchor - Double(size.width / 2) * framing.scale
        // Polish B3: while it comes it stands its rise lower, in whole game px.
        let bottom = framing.deviceY(lift: mark.lift - Double(mark.rise))
        return SIMD4<Float>(Float(left), Float(bottom - height), Float(width), Float(height))
    }

    /// The marks as emissive actors (drawn after every figure, unlit), the night's tint on them. Polish B3: a sprite in
    /// the frame list at its share (`tint.w`, the actor's alpha) and its whole-px rise; never scaled.
    static func actors(_ marks: [TouchMark], framing: TouchFraming, night: Double) -> [ActorInstance] {
        let tint = TouchRules.markTint(night: night)
        var list: [ActorInstance] = []
        for mark in marks where !mark.hidden && mark.tagShare > MarkPresence.faintest {
            let rect = rect(mark, framing: framing)
            guard rect.x + rect.z >= 0, rect.x <= Float(framing.physicalWidth) else { continue }
            list.append(ActorInstance(sprite: mark.sprite, frame: mark.pressed ? 1 : 0, rect: rect,
                                      tint: SIMD4<Float>(tint.x, tint.y, tint.z, Float(min(1, mark.tagShare))),
                                      flipped: false, isEmissive: true, isLit: true))
        }
        return list
    }

    /// The pools at the marked things' feet, 5 px above the walk line. Polish B3: each at its mark's share.
    static func pools(_ marks: [TouchMark]) -> [LightSource] {
        marks.map { mark in
            LightSource(kind: .window, x: mark.poolX, y: 5, radius: TouchRules.poolRadius,
                        color: GamePalette.fireGold,
                        intensity: TouchRules.poolStrength * (mark.pressed ? TouchRules.pressedPool : 1) * mark.alpha)
        }
    }
}

/// Polish B3 (M2 "signs on the walked world cut in and out"; law 1, quick): one mark as it comes and goes. `mark` is its
/// latest place and look (a thing that moves takes it along; one that goes keeps its last); `whole` the presence of the
/// whole mark (tag, pool, rim, footing), `tag` the tag's own while it gives way to a board; `wanted` whether the frame
/// still asks for it; `order` its place among the wanted. Picture state: never saved.
struct MarkShow: Sendable, Equatable {
    var mark: TouchMark
    var whole: Presence
    var tag: Presence
    var wanted: Bool
    var order: Int
}

/// The marks' presence (polish B3): a mark comes at quick (0.15 s, ease-out, rising 2 whole game px to its place) and
/// goes at quick out (0.10 s, ease-in, in place); under Reduce Motion it is alpha only, at quick. A mark that stays
/// keeps its presence whatever happens around it: it never moves, flickers or comes again. Pure; the model steps it
/// with the frame's seconds (`stepMarkShows`) and merges the marks each frame asks for (`currentMarks`).
enum MarkPresence {
    /// Below this share a mark is not drawn.
    static let faintest = 0.003

    /// The marks this frame asks for (already chosen, in order) into `shows`: a new one starts gone and 2 px low, one
    /// that stays takes its new place and look and keeps its presence, one no longer asked for goes from where it is.
    static func merge(_ shows: inout [String: MarkShow], wanted: [TouchMark]) {
        var seen: Set<String> = []
        for (index, mark) in wanted.enumerated() {
            let key = mark.id.isEmpty ? "\(mark.sprite)@\(mark.x)" : mark.id
            seen.insert(key)
            if var show = shows[key] {
                show.mark = mark
                show.wanted = true
                show.order = index
                shows[key] = show
            } else {
                shows[key] = MarkShow(mark: mark, whole: Presence(token: .quick, shown: false),
                                      tag: Presence(token: .quick, shown: !mark.hidden), wanted: true, order: index)
            }
        }
        for key in shows.keys where !seen.contains(key) {
            shows[key]?.wanted = false
        }
    }

    /// One step of `seconds`: each mark toward whole (wanted) or gone; a gone mark that is no longer wanted is dropped.
    static func step(_ shows: inout [String: MarkShow], seconds: Double, mode: MotionMode) {
        for key in Array(shows.keys) {
            guard var show = shows[key] else { continue }
            show.whole.step(seconds, shown: show.wanted, mode: mode)
            show.tag.step(seconds, shown: !show.mark.hidden, mode: mode)
            if !show.wanted && show.whole.isGone {
                shows[key] = nil
            } else {
                shows[key] = show
            }
        }
    }

    /// The marks to draw: the wanted in their order, then those going (by key), each with its share and rise; a mark
    /// not yet begun (share 0) is left out.
    static func drawn(_ shows: [String: MarkShow]) -> [TouchMark] {
        let ordered = shows.sorted { a, b in
            if a.value.wanted != b.value.wanted { return a.value.wanted }
            if a.value.wanted && a.value.order != b.value.order { return a.value.order < b.value.order }
            return a.key < b.key
        }
        var list: [TouchMark] = []
        for (_, show) in ordered where show.whole.alpha > faintest {
            var mark = show.mark
            mark.alpha = show.whole.alpha
            mark.rise = show.whole.rise
            mark.tagAlpha = show.tag.alpha
            mark.hidden = mark.tagShare <= faintest
            list.append(mark)
        }
        return list
    }
}
