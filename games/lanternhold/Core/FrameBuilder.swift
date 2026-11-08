/// Builds the immutable `FrameDesc` of one frame from the scene, the clock and the camera (DESIGN.md "Tech plan",
/// docs/research-rendering.md 5.3). Pure: no state, no time source, the same inputs give an equal frame. Everything off
/// screen is culled, so the instance and light counts stay inside the budget wherever the camera stands.
enum FrameBuilder {
    /// Bands of the `banded` light style.
    static let lightBands = 4
    /// Fog drift speeds in game px/s (fog A behind the world, fog B in front).
    static let fogDriftA = 3.0
    static let fogDriftB = 5.0
    /// Ground rows of the fog strips: fog A sits on the ground line, fog B a little lower, in front of the feet.
    static let fogYA = -4.0
    static let fogYB = -14.0
    /// Colour of the creatures' eye glints.
    static let eyeColor = SIMD4<Float>(1.0, 0.86, 0.55, 1)

    /// Geometry shared by every part of one frame.
    private struct Geometry {
        let scale: Int
        let targetWidth: Int
        let targetHeight: Int
        let groundRow: Int
        let groundDeviceY: Int
        let physicalWidth: Int
        let offsets: [PlaneOffset]

        func whole(_ plane: Plane) -> Double { Double(offsets[plane.rawValue].whole) }

        /// True when a span starting at target column `left`, `width` wide, touches the target.
        func isVisible(left: Double, width: Double) -> Bool {
            left + width >= -1 && left <= Double(targetWidth) + 1
        }

        /// Target row of the top of something `height` tall whose bottom is `y` above the ground line.
        func top(y: Double, height: Double) -> Double {
            Double(groundRow) - y - height
        }
    }

    /// The frame for `scene` at the clock's hour, seen by `camera` on a screen with `pixelScale`.
    static func build(scene: PlaceholderScene, clock: DayClock, camera: Camera, pixelScale: PixelScale,
                      options: FrameOptions) -> FrameDesc {
        let scale = pixelScale.scale
        let targetHeight = pixelScale.targetHeight
        let geometry = Geometry(scale: scale,
                                targetWidth: pixelScale.targetWidth,
                                targetHeight: targetHeight,
                                groundRow: Camera.groundRow(targetHeight: targetHeight),
                                groundDeviceY: Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                                    scale: scale),
                                physicalWidth: pixelScale.physicalWidth,
                                offsets: camera.offsets(scale: scale))
        let hour = clock.hour
        let ambient = AmbientRamp.sample(at: hour)
        let animTime = options.flickerTime ?? clock.elapsed
        let bankEdgeX = scene.bankEdge(hour: hour)

        var planeSprites: [[SpriteInstance]] = Array(repeating: [], count: Plane.allCases.count)
        var emissives: [EmissiveInstance] = []

        emissives.append(contentsOf: skyEmissives(ambient: ambient, hour: hour, geometry: geometry))
        planeSprites[Plane.world.rawValue].append(contentsOf: groundTiles(geometry: geometry))
        addProps(scene: scene, ambient: ambient, animTime: animTime, options: options, geometry: geometry,
                 sprites: &planeSprites, emissives: &emissives)
        planeSprites[Plane.world.rawValue].append(contentsOf: bankTiles(edgeX: bankEdgeX, geometry: geometry))

        var fog: [FogLayer] = []
        if options.effects.fog {
            let layers = fogLayers(ambient: ambient, animTime: animTime, reduceMotion: options.reduceMotion)
            for layer in layers {
                let tiles = fogTiles(layer: layer, geometry: geometry)
                planeSprites[layer.plane.rawValue].append(contentsOf: tiles)
            }
            fog = layers
        }

        let lights = frameLights(scene: scene, ambient: ambient, bankEdgeX: bankEdgeX, animTime: animTime,
                                 options: options, geometry: geometry)
        let field = scene.battleField(hour: hour)
        let actors = actorInstances(scene: scene, field: field, ambient: ambient, animTime: animTime,
                                    camera: camera, options: options, geometry: geometry)

        var planes: [PlaneLayer] = []
        for plane in Plane.allCases {
            planes.append(PlaneLayer(offset: geometry.offsets[plane.rawValue], sprites: planeSprites[plane.rawValue]))
        }
        let spriteCount = planeSprites.reduce(0) { $0 + $1.count }
        let counts = FrameCounts(sprites: spriteCount, actors: actors.count, emissives: emissives.count,
                                 lights: lights.count)
        let kingScreenX = camera.kingScreenX(kingX: scene.king.x, scale: scale, mode: options.actorMode)
        let bankEdge = Float(bankEdgeX - geometry.whole(.world))

        return FrameDesc(scale: scale,
                         physicalWidth: pixelScale.physicalWidth,
                         physicalHeight: pixelScale.physicalHeight,
                         targetWidth: pixelScale.targetWidth,
                         targetHeight: targetHeight,
                         groundRow: geometry.groundRow,
                         groundDeviceY: geometry.groundDeviceY,
                         hour: hour,
                         phase: clock.phase,
                         cameraX: camera.x,
                         kingX: scene.king.x,
                         kingScreenX: kingScreenX,
                         planes: planes,
                         actors: actors,
                         lights: lights,
                         emissives: emissives,
                         fog: fog,
                         ambient: ambient,
                         skyTop: ambient.skyTop,
                         skyBottom: ambient.skyBottom,
                         starAlpha: ambient.starAlpha,
                         bankEdge: bankEdge,
                         bankAmbientScale: Float(DarknessBank.ambientScale),
                         lightStyle: options.lightStyle,
                         lightBands: lightBands,
                         bloom: options.effects.bloom,
                         debugLights: options.debugLights,
                         counts: counts)
    }

    // MARK: - Sky

    /// Stars, the moon and the sun on the sky plane (parallax 0: target pixels are screen pixels).
    private static func skyEmissives(ambient: AmbientSample, hour: Double, geometry: Geometry) -> [EmissiveInstance] {
        var list: [EmissiveInstance] = []
        let width = geometry.targetWidth
        let ground = geometry.groundRow

        if ambient.starAlpha > 0.01 {
            let tile = SpriteID.starField.size
            let rows = ground - 40 >= 2 * tile.height ? [0, tile.height] : [0]
            for row in rows {
                var column = 0
                while column < width {
                    let rect = SIMD4<Float>(Float(column), Float(row), Float(tile.width), Float(tile.height))
                    let color = SIMD4<Float>(1, 1, 1, ambient.starAlpha)
                    list.append(EmissiveInstance(sprite: .starField, plane: .sky, rect: rect, color: color))
                    column += tile.width
                }
            }
        }

        if ambient.moonHeight > -0.05 {
            let size = SpriteID.moon.size
            let centre = Double(width) * 0.72
            let lift = Int((Double(ambient.moonHeight) * 90).rounded())
            let top = max(2, ground - 70 - lift)
            let left = Int(centre.rounded()) - size.width / 2
            let alpha = min(1, max(0, ambient.moonHeight * 3 + 0.3))
            let moon = GamePalette.moon
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            let color = SIMD4<Float>(moon.x, moon.y, moon.z, alpha)
            list.append(EmissiveInstance(sprite: .moon, plane: .sky, rect: rect, color: color))
        }

        if ambient.sunHeight > -0.1 {
            let size = SpriteID.sun.size
            let progress = min(1, max(0, (hour - 6) / 13))
            let centre = Double(width) * (0.85 - 0.7 * progress)
            let lift = Int((Double(ambient.sunHeight) * 110).rounded())
            let top = max(2, ground - 40 - lift)
            let left = Int(centre.rounded()) - size.width / 2
            let alpha = min(1, max(0, ambient.sunHeight * 5 + 0.5))
            let warm = min(1, max(0, ambient.sunHeight * 2 + 0.3))
            let low = GamePalette.ember
            let high = GamePalette.fireWhite
            let tone = low + (high - low) * warm
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            let color = SIMD4<Float>(tone.x, tone.y, tone.z, alpha)
            list.append(EmissiveInstance(sprite: .sun, plane: .sky, rect: rect, color: color))
        }
        return list
    }

    // MARK: - World plane tiles

    /// Ground tiles under the ground line across the visible part of the world.
    private static func groundTiles(geometry: Geometry) -> [SpriteInstance] {
        let size = SpriteID.ground.size
        let tile = Double(size.width)
        let whole = geometry.whole(.world)
        let first = Int((whole / tile).rounded(.down))
        let last = Int(((whole + Double(geometry.targetWidth)) / tile).rounded(.down))
        var list: [SpriteInstance] = []
        for index in first...max(first, last) {
            let worldX = Double(index) * tile
            if worldX < 0 || worldX >= WorldLayout.width { continue }
            let left = worldX - whole
            guard geometry.isVisible(left: left, width: tile) else { continue }
            let top = geometry.top(y: -Double(size.height), height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .ground, frame: 0, rect: rect, tint: SIMD4<Float>(1, 1, 1, 1),
                                       flipped: false))
        }
        return list
    }

    /// The darkness bank: dark tiles from the world's left end up to its edge, drawn in front of the world props.
    private static func bankTiles(edgeX: Double, geometry: Geometry) -> [SpriteInstance] {
        let edge = edgeX.rounded(.down)
        let whole = geometry.whole(.world)
        let edgeSize = SpriteID.darknessEdge.size
        let bodySize = SpriteID.darknessBank.size
        let baseY = -Double(WorldLayout.groundRowsBelow)
        let white = SIMD4<Float>(1, 1, 1, 1)
        var list: [SpriteInstance] = []

        let bodyEnd = edge - Double(edgeSize.width)
        var x = 0.0
        while x < bodyEnd {
            let left = x - whole
            if geometry.isVisible(left: left, width: Double(bodySize.width)) {
                let top = geometry.top(y: baseY, height: Double(bodySize.height))
                let rect = SIMD4<Float>(Float(left), Float(top), Float(bodySize.width), Float(bodySize.height))
                list.append(SpriteInstance(sprite: .darknessBank, frame: 0, rect: rect, tint: white, flipped: false))
            }
            x += Double(bodySize.width)
        }

        let edgeLeft = bodyEnd - whole
        if geometry.isVisible(left: edgeLeft, width: Double(edgeSize.width)) {
            let top = geometry.top(y: baseY, height: Double(edgeSize.height))
            let rect = SIMD4<Float>(Float(edgeLeft), Float(top), Float(edgeSize.width), Float(edgeSize.height))
            list.append(SpriteInstance(sprite: .darknessEdge, frame: 0, rect: rect, tint: white, flipped: false))
        }
        return list
    }

    // MARK: - Props

    /// Every visible prop as a plane sprite, in draw order (plane, z, id), with its emissive parts.
    private static func addProps(scene: PlaceholderScene, ambient: AmbientSample, animTime: Double,
                                 options: FrameOptions, geometry: Geometry,
                                 sprites: inout [[SpriteInstance]], emissives: inout [EmissiveInstance]) {
        let ordered = scene.props.sorted { ($0.plane, $0.z, $0.id) < ($1.plane, $1.z, $1.id) }
        for prop in ordered {
            let left = prop.x - geometry.whole(prop.plane)
            let width = Double(prop.width)
            let height = Double(prop.height)
            guard geometry.isVisible(left: left, width: width) else { continue }
            let top = geometry.top(y: prop.y, height: height)
            let rect = SIMD4<Float>(Float(left), Float(top), Float(prop.width), Float(prop.height))
            let tint = SIMD4<Float>(prop.shade, prop.shade, prop.shade, 1)
            let sprite = SpriteInstance(sprite: prop.sprite, frame: 0, rect: rect, tint: tint, flipped: prop.flipped)
            sprites[prop.plane.rawValue].append(sprite)

            for part in prop.emissive {
                if part.isFire && !prop.isLit { continue }
                if let emissive = emissiveInstance(part: part, prop: prop, left: left, ambient: ambient,
                                                   animTime: animTime, options: options, geometry: geometry) {
                    emissives.append(emissive)
                }
            }
        }
    }

    /// One emissive part of a prop, or nil while it is dark (a window by day).
    private static func emissiveInstance(part: EmissivePart, prop: Prop, left: Double, ambient: AmbientSample,
                                         animTime: Double, options: FrameOptions,
                                         geometry: Geometry) -> EmissiveInstance? {
        let size = part.sprite.size
        var strength = part.intensity
        if part.fadesByDay {
            strength *= ambient.torchStrength
        }
        if let seed = part.flickerSeed {
            let flicker = Flicker.sample(seed: seed, time: animTime, reduceMotion: options.reduceMotion)
            strength *= Float(flicker.intensity)
        }
        guard strength > 0.01 else { return nil }
        let dx = prop.flipped ? Double(prop.width) - part.dx - Double(size.width) : part.dx
        let x = left + dx
        let top = geometry.top(y: prop.y + part.dy, height: Double(size.height))
        let rect = SIMD4<Float>(Float(x), Float(top), Float(size.width), Float(size.height))
        let rgb = part.color * strength
        let color = SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)
        return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color)
    }

    // MARK: - Fog

    /// The two fog planes at this hour (density from the ramp; fog B thinner).
    private static func fogLayers(ambient: AmbientSample, animTime: Double, reduceMotion: Bool) -> [FogLayer] {
        let slow = reduceMotion ? Flicker.reducedRateScale : 1.0
        let driftA = Float(animTime * fogDriftA * slow)
        let driftB = Float(animTime * fogDriftB * slow)
        let back = FogLayer(plane: .fogA, color: ambient.fogColor, density: ambient.fogDensity * 0.9,
                            lightShare: 0.6, drift: driftA)
        let front = FogLayer(plane: .fogB, color: ambient.fogColor, density: ambient.fogDensity * 0.6,
                             lightShare: 0.8, drift: driftB)
        return [back, front]
    }

    /// Fog strips across the visible part of a fog plane, moved by the drift in whole game pixels.
    private static func fogTiles(layer: FogLayer, geometry: Geometry) -> [SpriteInstance] {
        let size = SpriteID.fogStrip.size
        let tile = Double(size.width)
        let whole = geometry.whole(layer.plane)
        let drift = Double(layer.drift).rounded(.down).truncatingRemainder(dividingBy: tile)
        let baseY = layer.plane == .fogA ? fogYA : fogYB
        let top = geometry.top(y: baseY, height: Double(size.height))
        let tint = SIMD4<Float>(layer.color.x, layer.color.y, layer.color.z, layer.density)
        let first = Int(((whole + drift) / tile).rounded(.down)) - 1
        let count = geometry.targetWidth / size.width + 3
        var list: [SpriteInstance] = []
        for index in first..<(first + count) {
            let planeX = Double(index) * tile - drift
            let left = planeX - whole
            guard geometry.isVisible(left: left, width: tile) else { continue }
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .fogStrip, frame: 0, rect: rect, tint: tint, flipped: index % 2 != 0))
        }
        return list
    }

    // MARK: - Lights

    /// The scene's lights for the light pass: flicker applied, torches faded by day, radii × 0.6 inside the darkness
    /// bank, culled to the visible width.
    private static func frameLights(scene: PlaceholderScene, ambient: AmbientSample, bankEdgeX: Double,
                                    animTime: Double, options: FrameOptions, geometry: Geometry) -> [FrameLight] {
        let bank = DarknessBank(edgeX: bankEdgeX)
        let whole = geometry.whole(.world)
        let torch = Double(ambient.torchStrength)
        var list: [FrameLight] = []
        for source in scene.lightSources() {
            var radius = source.radius
            if bank.contains(x: source.x) { radius *= DarknessBank.radiusScale }
            var intensity = source.intensity
            if source.kind.fadesByDay {
                intensity *= torch
            } else {
                intensity *= 0.35 + 0.65 * torch
            }
            var color = source.color
            if source.kind.flickers {
                let flicker = Flicker.sample(seed: source.flickerSeed, time: animTime,
                                             reduceMotion: options.reduceMotion)
                intensity *= flicker.intensity
                radius += Double(flicker.radiusJitter)
                let shifted = color + flicker.colorShift
                color = clampUnit(shifted)
            }
            guard intensity > 0.01, radius > 0 else { continue }
            let centreX = source.x - whole
            guard geometry.isVisible(left: centreX - radius, width: 2 * radius) else { continue }
            let centreY = Double(geometry.groundRow) - source.y
            let circle = SIMD4<Float>(Float(centreX), Float(centreY), Float(radius), Float(intensity))
            let rgba = SIMD4<Float>(color.x, color.y, color.z, 0)
            list.append(FrameLight(circle: circle, color: rgba, ellipseY: Float(LightField.ellipseY), kind: source.kind))
        }
        return list
    }

    /// Each channel clamped to 0 ... 1.
    private static func clampUnit(_ value: SIMD3<Float>) -> SIMD3<Float> {
        let zero = SIMD3<Float>(repeating: 0)
        let one = SIMD3<Float>(repeating: 1)
        return value.clamped(lowerBound: zero, upperBound: one)
    }

    // MARK: - Actors

    /// Creatures (with their eye glints), archers, citizens and the king last, in device pixels.
    private static func actorInstances(scene: PlaceholderScene, field: LightField, ambient: AmbientSample,
                                       animTime: Double, camera: Camera, options: FrameOptions,
                                       geometry: Geometry) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let white = SIMD4<Float>(1, 1, 1, 1)
        let unlitAlpha = max(0, 1 - ambient.torchStrength)

        for actor in scene.actors {
            let sprite = actor.kind.sprite
            let frame = idleFrame(time: animTime + actor.phase, frames: sprite.frameCount)
            let flipped = actor.facing < 0
            if actor.kind.isCreature {
                let lit = field.isLit(x: actor.x, y: actor.y + 4)
                let alpha: Float = lit ? 1 : unlitAlpha
                if alpha > 0.001 {
                    let rect = actorRect(sprite: sprite, x: actor.x, y: actor.y, camera: camera, options: options,
                                         geometry: geometry)
                    if isOnScreen(rect, geometry: geometry) {
                        let tint = SIMD4<Float>(1, 1, 1, alpha)
                        list.append(ActorInstance(sprite: sprite, frame: frame, rect: rect, tint: tint,
                                                  flipped: flipped, isEmissive: false, isLit: lit))
                    }
                }
                let eye = actor.kind.eyeOffset
                let eyeX = actor.x + eye.dx * Double(actor.facing)
                let eyeRect = actorRect(sprite: .eyeGlints, x: eyeX, y: actor.y + eye.dy, camera: camera,
                                        options: options, geometry: geometry)
                if isOnScreen(eyeRect, geometry: geometry) {
                    list.append(ActorInstance(sprite: .eyeGlints, frame: 0, rect: eyeRect, tint: eyeColor,
                                              flipped: flipped, isEmissive: true, isLit: lit))
                }
            } else {
                let rect = actorRect(sprite: sprite, x: actor.x, y: actor.y, camera: camera, options: options,
                                     geometry: geometry)
                if isOnScreen(rect, geometry: geometry) {
                    let lit = field.isLit(x: actor.x, y: actor.y + 4)
                    list.append(ActorInstance(sprite: sprite, frame: frame, rect: rect, tint: white,
                                              flipped: flipped, isEmissive: false, isLit: lit))
                }
            }
        }

        let king = scene.king
        let kingFrame = kingFrameIndex(king: king, animTime: animTime)
        let kingRect = actorRect(sprite: .king, x: king.x, y: 0, camera: camera, options: options, geometry: geometry)
        if isOnScreen(kingRect, geometry: geometry) {
            let lit = field.isLit(x: king.x, y: 4)
            list.append(ActorInstance(sprite: .king, frame: kingFrame, rect: kingRect, tint: white,
                                      flipped: king.facing < 0, isEmissive: false, isLit: lit))
        }
        return list
    }

    /// Idle animation at two frames per second.
    static func idleFrame(time: Double, frames: Int) -> Int {
        let count = max(1, min(2, frames))
        let step = Int((time * 2).rounded(.down))
        return ((step % count) + count) % count
    }

    /// The king's frame: idle 0 ... 1 standing, walk 2 ... 5 by distance (one frame per 7 game px), so his feet
    /// match the ground at any speed.
    static func kingFrameIndex(king: KingState, animTime: Double) -> Int {
        guard king.isWalking else { return idleFrame(time: animTime, frames: 2) }
        let walkStep = Int((king.x / 7).rounded(.down))
        return 2 + ((walkStep % 4) + 4) % 4
    }

    /// An actor's quad in device pixels: anchored at its bottom centre, its texels s × s blocks.
    private static func actorRect(sprite: SpriteID, x: Double, y: Double, camera: Camera, options: FrameOptions,
                                  geometry: Geometry) -> SIMD4<Float> {
        let scale = geometry.scale
        let size = sprite.size
        let anchor = camera.deviceX(worldX: x, scale: scale, mode: options.actorMode)
        let width = size.width * scale
        let height = size.height * scale
        let left = anchor - width / 2
        let lift: Int
        switch options.actorMode {
        case .smooth: lift = Int((y * Double(scale)).rounded())
        case .snapped: lift = Int(y.rounded()) * scale
        }
        let bottom = geometry.groundDeviceY - lift
        return SIMD4<Float>(Float(left), Float(bottom - height), Float(width), Float(height))
    }

    private static func isOnScreen(_ rect: SIMD4<Float>, geometry: Geometry) -> Bool {
        rect.x + rect.z >= 0 && rect.x <= Float(geometry.physicalWidth)
    }
}
