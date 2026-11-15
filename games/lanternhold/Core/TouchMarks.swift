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
    /// Stage-3-interface (stage-2 critic look 2, high 2): a slip names the thing now and takes the mark's place, so the
    /// mark is not drawn (its rim and pool stay).
    var hidden = false
    /// No gold rim on the thing (the barracks while Marek's cart stands before them: the rim read as the cart's).
    var noRim = false
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
                             footing: thing.footing, rimX: thing.rimX, noRim: thing.noRim)
        }
    }

    /// The device rect of a mark: its tip (frame x 7, its bottom row) over `x`, at `lift` above the walk line.
    static func rect(_ mark: TouchMark, framing: TouchFraming) -> SIMD4<Float> {
        let size = mark.sprite.size
        let anchor = framing.deviceX(stageX: mark.x)
        let width = Double(size.width) * framing.scale
        let height = Double(size.height) * framing.scale
        let left = anchor - Double(size.width / 2) * framing.scale
        let bottom = framing.deviceY(lift: mark.lift)
        return SIMD4<Float>(Float(left), Float(bottom - height), Float(width), Float(height))
    }

    /// The marks as emissive actors (drawn after every figure, unlit), the night's tint on them.
    static func actors(_ marks: [TouchMark], framing: TouchFraming, night: Double) -> [ActorInstance] {
        let tint = TouchRules.markTint(night: night)
        var list: [ActorInstance] = []
        for mark in marks where !mark.hidden {
            let rect = rect(mark, framing: framing)
            guard rect.x + rect.z >= 0, rect.x <= Float(framing.physicalWidth) else { continue }
            list.append(ActorInstance(sprite: mark.sprite, frame: mark.pressed ? 1 : 0, rect: rect,
                                      tint: SIMD4<Float>(tint.x, tint.y, tint.z, 1), flipped: false,
                                      isEmissive: true, isLit: true))
        }
        return list
    }

    /// The pools at the marked things' feet, 5 px above the walk line.
    static func pools(_ marks: [TouchMark]) -> [LightSource] {
        marks.map { mark in
            LightSource(kind: .window, x: mark.poolX, y: 5, radius: TouchRules.poolRadius,
                        color: GamePalette.fireGold,
                        intensity: TouchRules.poolStrength * (mark.pressed ? TouchRules.pressedPool : 1))
        }
    }
}
