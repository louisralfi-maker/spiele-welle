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
    /// The ground mist's density against the ramp's fog density (M1b: 0.7 of the milestone 1 mist, so the valley and
    /// the castle's foot stay clear).
    static let fogScale: Float = 0.7
    /// Window glass glows with its colour × the ramp's torch strength × this.
    static let glassGain: Float = 0.9
    /// The keep's glass seen across the gorge stands in the mid plane's haze (M2b review: at full strength its panes
    /// read as two eyes in the dark): glass on the gorge's mid plane glows at this share.
    static let gorgeMidGlass: Float = 0.45
    /// The lowest a top-anchored rock lip may hang, in rows above the ground line (polish after the art review): 20
    /// rows above the statue's bowl fire (y 119), so the gorge's signature prop stays clear on every phone; 175-row
    /// screens show 36 of a lip's 48 rows, 154-row screens 15, the 135-row look none.
    static let lipLowestBottom = 139.0
    /// Colour of the creatures' eye glints.
    static let eyeColor = SIMD4<Float>(1.0, 0.86, 0.55, 1)
    /// Scene polish 2: how dark the castle's cast shadow gets in full sun (black over-blended at this alpha), and how
    /// thick its ground mist gets at night (white at this alpha times the sprite's own).
    static let sunShadowMax: Float = 0.55
    static let mistMax: Float = 0.9

    // Look 2 (DESIGN.md "Look 2 port", tools/scenemock/mock.py's LOOK2): painted fog banks instead of the stretched
    // strip, each at its own height, denser than look 1's (× `look2FogScale`; the band between the mid and near
    // planes at the ramp's own density) and thinner by region in the shader; window glass a step brighter; the
    // castle's ground mist at a third (the banks do most); chimney smoke over the town's cottages.
    static let look2FogScale: Float = 1.2
    static let look2MistBandShare: Float = 1.0
    static let look2FogYA = -4.0
    static let look2FogYB = -14.0
    static let look2MistBandY = -2.0
    /// The mist band drifts slower than the banks (game px/s).
    static let look2MistBandDrift = 1.5
    static let look2GlassGain: Float = 1.3
    static let look2CastleMist: Float = 0.35
    static let look2SmokeTint = SIMD4<Float>(0.74, 0.74, 0.76, 0.55)
    /// The smoke's bottom row above the ground line, and the chimney's x in the house's sprite (plain, mirrored).
    static let look2SmokeY = 45.0
    static let look2ChimneyX = (plain: 49.0, flipped: 14.0)

    /// Geometry shared by every part of one frame.
    private struct Geometry {
        let scale: Int
        let targetWidth: Int
        let targetHeight: Int
        let groundRow: Int
        let groundDeviceY: Int
        let physicalWidth: Int
        let offsets: [PlaneOffset]
        /// The camera's focus (the screen centre) in world game pixels.
        let focusX: Double

        func whole(_ plane: Plane) -> Double { Double(offsets[plane.rawValue].whole) }

        /// True when a span starting at target column `left`, `width` wide, touches the target.
        func isVisible(left: Double, width: Double) -> Bool {
            left + width >= -1 && left <= Double(targetWidth) + 1
        }

        /// Target row of the top of something `height` tall whose bottom is `y` above the ground line.
        func top(y: Double, height: Double) -> Double {
            Double(groundRow) - y - height
        }

        /// The bottom of a prop above the ground line: its `y`, or for a top-anchored prop the bottom that puts its
        /// top row `y` rows below the screen's top row, but never below `FrameBuilder.lipLowestBottom` (on short
        /// screens the lip slides up past the top edge instead of covering the warden statue's crown and bowl fire).
        func bottom(of prop: Prop) -> Double {
            switch prop.anchor {
            case .ground: return prop.y
            case .top: return max(Double(groundRow) - prop.y - Double(prop.height), FrameBuilder.lipLowestBottom)
            }
        }
    }

    /// The emissive pass in draw order: glow and glass as each prop is drawn, and an occluder for every later sprite
    /// of the mid, world or foreground plane that covers glow added before it (ART.md "Renderer additions": a light
    /// never shines through what stands in front of it). Only sprites that overlap earlier glow become occluders.
    private struct EmissiveList {
        var items: [EmissiveInstance] = []
        private var glowRects: [SIMD4<Float>] = []

        mutating func add(_ item: EmissiveInstance) {
            items.append(item)
            glowRects.append(item.rect)
        }

        /// A sprite drawn now on `plane` hides the glow under its opaque pixels.
        mutating func occlude(_ sprite: SpriteInstance, plane: Plane) {
            guard plane == .mid || plane == .near || plane == .world || plane == .foreground else { return }
            let r = sprite.rect
            let covers = glowRects.contains { g in
                g.x < r.x + r.z && r.x < g.x + g.z && g.y < r.y + r.w && r.y < g.y + g.w
            }
            guard covers else { return }
            let black = SIMD4<Float>(0, 0, 0, 1)
            items.append(EmissiveInstance(sprite: sprite.sprite, plane: plane, rect: r, color: black, kind: .occluder,
                                          flipped: sprite.flipped, frame: sprite.frame))
        }
    }

    /// The frame for `scene` at the clock's hour, seen by `camera` on a screen with `pixelScale`. In game mode
    /// `entities` (M2b, `EntityFrames`) brings the simulation: its props join the scene's, its glow joins the world
    /// plane's, its light list replaces the scene's and its actors replace the scene's actors and king.
    static func build(scene: PlaceholderScene, clock: DayClock, camera: Camera, pixelScale: PixelScale,
                      options: FrameOptions, entities: EntityLayer? = nil) -> FrameDesc {
        let scale = pixelScale.scale
        let targetHeight = pixelScale.targetHeight
        let geometry = Geometry(scale: scale,
                                targetWidth: pixelScale.targetWidth,
                                targetHeight: targetHeight,
                                groundRow: Camera.groundRow(targetHeight: targetHeight),
                                groundDeviceY: Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                                    scale: scale),
                                physicalWidth: pixelScale.physicalWidth,
                                offsets: camera.offsets(scale: scale),
                                focusX: camera.focusX)
        let hour = clock.hour
        let ambient = AmbientRamp.sample(at: hour, look: options.look)
        let animTime = options.flickerTime ?? clock.elapsed
        let bankEdgeX = scene.bankEdge(hour: hour)

        var planeSprites: [[SpriteInstance]] = Array(repeating: [], count: Plane.allCases.count)
        var glow = EmissiveList()

        // Back to front, so the emissive pass sees every sprite in draw order: the props of each plane (sorted by z,
        // then as listed), on the world plane the ground before them and the darkness bank after them.
        let props = scene.props + (entities?.props ?? [])
        let ordered = props.sorted { ($0.plane, $0.z, $0.id) < ($1.plane, $1.z, $1.id) }
        var next = 0
        for plane in Plane.allCases {
            if plane == .world {
                let tiles = options.look == .two ? laneTiles(geometry: geometry) : groundTiles(geometry: geometry)
                for tile in tiles {
                    glow.occlude(tile, plane: .world)
                    planeSprites[plane.rawValue].append(tile)
                }
            }
            while next < ordered.count && ordered[next].plane == plane {
                addProp(ordered[next], ambient: ambient, hour: hour, animTime: animTime, options: options,
                        geometry: geometry, sprites: &planeSprites, glow: &glow)
                next += 1
            }
            if plane == .world {
                if options.look == .two {
                    planeSprites[plane.rawValue] += smoke(props: ordered, geometry: geometry)
                }
                for item in entities?.emissives(worldWhole: geometry.whole(.world), groundRow: geometry.groundRow,
                                                targetWidth: geometry.targetWidth) ?? [] {
                    glow.add(item)
                }
                for tile in bankTiles(edgeX: bankEdgeX, geometry: geometry) {
                    glow.occlude(tile, plane: .world)
                    planeSprites[plane.rawValue].append(tile)
                }
            }
        }
        let emissives = skyEmissives(ambient: ambient, hour: hour, geometry: geometry) + glow.items

        var fog: [FogLayer] = []
        if options.effects.fog {
            let layers = fogLayers(ambient: ambient, animTime: animTime, reduceMotion: options.reduceMotion,
                                   look: options.look)
            for layer in layers {
                let tiles = options.look == .two ? fogBankTiles(layer: layer, geometry: geometry)
                                                 : fogTiles(layer: layer, geometry: geometry)
                planeSprites[layer.plane.rawValue].append(contentsOf: tiles)
            }
            fog = layers
        }

        let lights = frameLights(sources: entities?.lights ?? scene.sceneLights(), ambient: ambient,
                                 bankEdgeX: bankEdgeX, animTime: animTime, options: options, geometry: geometry)
        let actors = entities?.actors ?? actorInstances(scene: scene, field: scene.battleField(hour: hour),
                                                        ambient: ambient, animTime: animTime, camera: camera,
                                                        options: options, geometry: geometry)

        var planes: [PlaneLayer] = []
        for plane in Plane.allCases {
            planes.append(PlaneLayer(offset: geometry.offsets[plane.rawValue], sprites: planeSprites[plane.rawValue]))
        }
        let spriteCount = planeSprites.reduce(0) { $0 + $1.count }
        let counts = FrameCounts(sprites: spriteCount, actors: actors.count, emissives: emissives.count,
                                 lights: lights.count)
        let kingScreenX = camera.kingScreenX(kingX: scene.king.x, scale: scale, mode: options.actorMode)
        let bankEdge = Float(bankEdgeX - geometry.whole(.world))

        var desc = FrameDesc(scale: scale,
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
        desc.look = options.look
        if options.look == .two {
            desc.rooms = rooms(props: ordered, geometry: geometry)
        }
        return desc
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

    /// Ground tiles under the ground line across the visible part of the world, up to the river bank.
    private static func groundTiles(geometry: Geometry) -> [SpriteInstance] {
        let size = SpriteID.ground.size
        let tile = Double(size.width)
        let whole = geometry.whole(.world)
        let first = Int((whole / tile).rounded(.down))
        let last = Int(((whole + Double(geometry.targetWidth)) / tile).rounded(.down))
        var list: [SpriteInstance] = []
        for index in first...max(first, last) {
            let worldX = Double(index) * tile
            if worldX < 0 || worldX >= WorldLayout.groundTileEnd { continue }
            let left = worldX - whole
            guard geometry.isVisible(left: left, width: tile) else { continue }
            let top = geometry.top(y: -Double(size.height), height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: groundTile(index), frame: 0, rect: rect,
                                       tint: SIMD4<Float>(1, 1, 1, 1), flipped: false))
        }
        return list
    }

    /// Look 2: the lane's tiles under the ground line (`SceneLayout.look2LaneTile`), up to the river bank.
    private static func laneTiles(geometry: Geometry) -> [SpriteInstance] {
        let size = SpriteID.laneMoorA.size
        let tile = Double(size.width)
        let whole = geometry.whole(.world)
        let first = Int((whole / tile).rounded(.down))
        let last = Int(((whole + Double(geometry.targetWidth)) / tile).rounded(.down))
        var list: [SpriteInstance] = []
        for index in first...max(first, last) {
            let worldX = Double(index) * tile
            if worldX < -tile || worldX >= WorldLayout.groundTileEnd { continue }
            let left = worldX - whole
            guard geometry.isVisible(left: left, width: tile) else { continue }
            let top = geometry.top(y: -Double(size.height), height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: SceneLayout.look2LaneTile(index: index), frame: 0, rect: rect,
                                       tint: SIMD4<Float>(1, 1, 1, 1), flipped: false))
        }
        return list
    }

    /// Look 2: chimney smoke over the town's cottages that stand (`SceneLayout.look2Smoke`), a translucent veil on
    /// the world plane that hides no glow.
    private static func smoke(props: [Prop], geometry: Geometry) -> [SpriteInstance] {
        let cottages: Set<SpriteID> = [.house, .houseB, .houseC]
        let size = SpriteID.d2Smoke.size
        var list: [SpriteInstance] = []
        for chimney in SceneLayout.look2Smoke {
            let stands = props.contains {
                $0.plane == .world && cottages.contains($0.sprite) && abs($0.x - chimney.x) < 0.5
            }
            guard stands else { continue }
            let centre = chimney.x + (chimney.flipped ? look2ChimneyX.flipped : look2ChimneyX.plain)
            let left = centre - Double(size.width / 2) - geometry.whole(.world)
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
            let top = geometry.top(y: look2SmokeY, height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .d2Smoke, frame: 0, rect: rect, tint: look2SmokeTint, flipped: false))
        }
        return list
    }

    /// Look 2: the cut-away rooms on screen (`SceneLayout.look2Interior`), at most two, each as x0, y0, x1, y1 in
    /// world target pixels (half open). The great hall is no room while its front wall stands before it.
    private static func rooms(props: [Prop], geometry: Geometry) -> [SIMD4<Float>] {
        let walled = props.contains { $0.sprite == .hallFront && $0.alpha > 0.5 }
        var list: [SIMD4<Float>] = []
        for prop in props where prop.plane == .world && prop.alpha > 0.5 {
            guard let box = SceneLayout.look2Interior(prop.sprite), list.count < 2 else { continue }
            if prop.sprite == .hallInterior && walled { continue }
            let left = prop.x - geometry.whole(.world)
            guard geometry.isVisible(left: left, width: Double(prop.width)) else { continue }
            let x0 = prop.flipped ? left + Double(prop.width - box.x1) : left + Double(box.x0)
            let x1 = prop.flipped ? left + Double(prop.width - box.x0) : left + Double(box.x1)
            let bottom = Double(geometry.groundRow) - geometry.bottom(of: prop)
            list.append(SIMD4<Float>(Float(x0), Float(bottom - Double(box.y1)), Float(x1),
                                     Float(bottom - Double(box.y0))))
        }
        return list
    }

    /// The ground tile at `index` (polish after the art review: one 64 px tile repeated put its stones at a fixed
    /// rhythm). Each tile boundary either carries the big stone that wraps across it or plain soil, picked by a hash of
    /// the boundary; the tile whose edges match both of its boundaries is drawn, so neighbours always join.
    static func groundTile(_ index: Int) -> SpriteID {
        let left = groundEdgeHasStone(index)
        let right = groundEdgeHasStone(index + 1)
        switch (left, right) {
        case (true, true): return .ground
        case (true, false): return .groundB
        case (false, true): return .groundC
        case (false, false): return .groundD
        }
    }

    /// Whether the big stone wraps across the boundary left of ground tile `index` (a fixed integer hash, the same as
    /// tools/scenemock/mock.py's).
    static func groundEdgeHasStone(_ index: Int) -> Bool {
        var h = UInt32(truncatingIfNeeded: index) &* 0x9E37_79B1
        h ^= h >> 16
        h = h &* 0x85EB_CA6B
        h ^= h >> 13
        return (h >> 7) & 1 == 0
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

        // Body tiles laid leftward from the edge tile, so none reaches past the edge.
        let bodyEnd = edge - Double(edgeSize.width)
        let bodyWidth = Double(bodySize.width)
        var x = bodyEnd - bodyWidth
        while x > -bodyWidth {
            let left = x - whole
            if geometry.isVisible(left: left, width: bodyWidth) {
                let top = geometry.top(y: baseY, height: Double(bodySize.height))
                let rect = SIMD4<Float>(Float(left), Float(top), Float(bodySize.width), Float(bodySize.height))
                list.append(SpriteInstance(sprite: .darknessBank, frame: 0, rect: rect, tint: white, flipped: false))
            }
            x -= bodyWidth
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

    /// The alpha of a baked cast shadow (scene polish 2): the sun's strength (full from a sun height of 0.18, none
    /// below −0.12: gone at night, faint at dawn and after sunset) times `sunShadowMax`; the long dusk shadow beyond
    /// the day one also times the evening weight (0 before 16:00, 1 from about 18:24), so the two never darken one
    /// pixel twice. The same as tools/scenemock/mock.py `shadow_alpha`.
    static func sunShadowAlpha(_ kind: SunShadow, ambient: AmbientSample, hour: Double) -> Float {
        let sun = min(1, max(0, (ambient.sunHeight + 0.12) / 0.3))
        var alpha = sunShadowMax * sun
        if kind == .dusk {
            let t = Float(min(1, max(0, (hour - 16) / 2.4)))
            alpha *= t * t * (3 - 2 * t)
        }
        return alpha
    }

    /// The alpha of a bank of ground mist (scene polish 2): the torch strength (0 by day, rising at dusk, full at
    /// night) times the hour's fog density against the night's 0.4 (at most 1.25: the dawn haze), times `mistMax` and
    /// the prop's own share. The same as mock.py `mist_alpha`.
    static func mistAlpha(_ share: Float, ambient: AmbientSample) -> Float {
        mistMax * share * min(1, max(0, ambient.torchStrength)) * min(1.25, ambient.fogDensity / 0.4)
    }

    /// One prop as a plane sprite (culled off screen), then its emissive sprites and window glass.
    private static func addProp(_ prop: Prop, ambient: AmbientSample, hour: Double, animTime: Double,
                                options: FrameOptions, geometry: Geometry, sprites: inout [[SpriteInstance]],
                                glow: inout EmissiveList) {
        // A prop that moves with another plane is placed by that plane's whole offset (within a game pixel of its
        // own sub-pixel shift) but drawn into its own plane's picture.
        let left = prop.x - geometry.whole(prop.movesWith ?? prop.plane)
        let width = Double(prop.width)
        let height = Double(prop.height)
        guard geometry.isVisible(left: left, width: width) else { return }
        var alpha: Float = 1
        if let fade = prop.fade {
            let share = (geometry.focusX - fade.lowerBound) / max(1, fade.upperBound - fade.lowerBound)
            alpha = Float(min(1, max(0, share)))
        }
        if let fadeOut = prop.fadeOut {
            let share = (geometry.focusX - fadeOut.lowerBound) / max(1, fadeOut.upperBound - fadeOut.lowerBound)
            alpha *= Float(1 - min(1, max(0, share)))
        }
        guard alpha > 0.003 else { return }
        let bottom = geometry.bottom(of: prop)
        let top = geometry.top(y: bottom, height: height)
        let rect = SIMD4<Float>(Float(left), Float(top), Float(prop.width), Float(prop.height))
        var tint = SIMD4<Float>(prop.shade, prop.shade, prop.shade, alpha * prop.alpha)
        // Scene polish 2: a cast shadow is black at the sun's strength, a mist bank white at the mist's; both are
        // translucent veils that hide no glow.
        var hidesGlow = true
        if let shadow = prop.sunShadow {
            let strength = sunShadowAlpha(shadow, ambient: ambient, hour: hour) * alpha * prop.alpha
            guard strength > 0.003 else { return }
            tint = SIMD4<Float>(0, 0, 0, strength)
            hidesGlow = false
        } else if let mist = prop.mist {
            let share: Float = options.look == .two ? look2CastleMist : 1
            let strength = mistAlpha(mist, ambient: ambient) * alpha * prop.alpha * share
            guard strength > 0.003 else { return }
            tint = SIMD4<Float>(1, 1, 1, strength)
            hidesGlow = false
        }
        let sprite = SpriteInstance(sprite: prop.sprite, frame: prop.frame, rect: rect, tint: tint,
                                    flipped: prop.flipped)
        if hidesGlow {
            glow.occlude(sprite, plane: prop.plane)
        }
        sprites[prop.plane.rawValue].append(sprite)

        for part in prop.emissive {
            if part.isFire && !prop.isLit { continue }
            // Look 2: a fading sprite's glow fades with it (the far castle's pane over the valley).
            if let emissive = emissiveInstance(part: part, prop: prop, left: left, bottom: bottom, ambient: ambient,
                                               animTime: animTime, options: options, geometry: geometry,
                                               fade: options.look == .two ? alpha : 1) {
                glow.add(emissive)
            }
        }
        let torch = ambient.torchStrength
        guard torch > 0.01 else { return }
        let haze: Float = prop.plane == .mid && prop.region == .gorge ? gorgeMidGlass : 1
        for mask in prop.masks {
            let gain = options.look == .two ? glassGain * look2GlassGain : glassGain
            let rgb = mask.color * (torch * gain * haze)
            let dx = prop.flipped ? width - mask.dx - Double(mask.width) : mask.dx
            let maskTop = geometry.top(y: bottom + mask.dy, height: Double(mask.height))
            let place = SIMD4<Float>(Float(left + dx), Float(maskTop), Float(mask.width), Float(mask.height))
            let source = SIMD4<Float>(Float(mask.dx), Float(height - mask.dy - Double(mask.height)),
                                      Float(mask.width), Float(mask.height))
            glow.add(EmissiveInstance(sprite: prop.sprite, plane: prop.plane, rect: place,
                                      color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1), kind: .glass, source: source,
                                      flipped: prop.flipped, frame: prop.frame))
        }
    }

    /// One emissive part of a prop, or nil while it is dark (a window by day).
    private static func emissiveInstance(part: EmissivePart, prop: Prop, left: Double, bottom: Double,
                                         ambient: AmbientSample, animTime: Double, options: FrameOptions,
                                         geometry: Geometry, fade: Float = 1) -> EmissiveInstance? {
        let size = part.sprite.size
        var strength = part.intensity * fade
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
        let top = geometry.top(y: bottom + part.dy, height: Double(size.height))
        let rect = SIMD4<Float>(Float(x), Float(top), Float(size.width), Float(size.height))
        let rgb = part.color * strength
        let color = SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)
        return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color)
    }

    // MARK: - Fog

    /// The two fog planes at this hour (density from the ramp × `fogScale`; fog B thinner). The light lab uses them
    /// too.
    /// Look 2 has three: the bank behind the play plane, the low mist over the lane and the mist band between the mid
    /// and near planes (`fogBankTiles`).
    static func fogLayers(ambient: AmbientSample, animTime: Double, reduceMotion: Bool,
                          look: LookVersion = .one) -> [FogLayer] {
        let slow = reduceMotion ? Flicker.reducedRateScale : 1.0
        let driftA = Float(animTime * fogDriftA * slow)
        let driftB = Float(animTime * fogDriftB * slow)
        if look == .two {
            let density = ambient.fogDensity
            return [
                FogLayer(plane: .fogA, color: ambient.fogColor, density: density * 0.9 * look2FogScale,
                         lightShare: 0.6, drift: driftA),
                FogLayer(plane: .fogB, color: ambient.fogColor, density: density * 0.6 * look2FogScale,
                         lightShare: 0.8, drift: driftB),
                FogLayer(plane: .mistBand, color: ambient.fogColor, density: density * look2MistBandShare,
                         lightShare: 0.6, drift: Float(animTime * look2MistBandDrift * slow)),
            ]
        }
        let back = FogLayer(plane: .fogA, color: ambient.fogColor, density: ambient.fogDensity * 0.9 * fogScale,
                            lightShare: 0.6, drift: driftA)
        let front = FogLayer(plane: .fogB, color: ambient.fogColor, density: ambient.fogDensity * 0.6 * fogScale,
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

    /// Look 2: one painted bank across the visible part of its plane (`d2FogBank` behind the play plane, `d2FogLow`
    /// over the lane, `d2MistBand` between the mid and near planes), seamless and never mirrored, moved by the drift
    /// in whole game pixels. The tint is the fog's colour at the layer's density; the shader thins it by region.
    private static func fogBankTiles(layer: FogLayer, geometry: Geometry) -> [SpriteInstance] {
        let sprite: SpriteID
        let baseY: Double
        switch layer.plane {
        case .fogA: (sprite, baseY) = (.d2FogBank, look2FogYA)
        case .fogB: (sprite, baseY) = (.d2FogLow, look2FogYB)
        default: (sprite, baseY) = (.d2MistBand, look2MistBandY)
        }
        let size = sprite.size
        let tile = Double(size.width)
        let whole = geometry.whole(layer.plane)
        let drift = Double(layer.drift).rounded(.down).truncatingRemainder(dividingBy: tile)
        let top = geometry.top(y: baseY, height: Double(size.height))
        let tint = SIMD4<Float>(layer.color.x, layer.color.y, layer.color.z, min(1, layer.density))
        let first = Int(((whole + drift) / tile).rounded(.down)) - 1
        let count = geometry.targetWidth / size.width + 3
        var list: [SpriteInstance] = []
        for index in first..<(first + count) {
            let left = Double(index) * tile - drift - whole
            guard geometry.isVisible(left: left, width: tile) else { continue }
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: sprite, frame: 0, rect: rect, tint: tint, flipped: false))
        }
        return list
    }

    // MARK: - Lights

    /// The scene's lights for the light pass: flicker applied, torches faded by day, radii × 0.6 inside the darkness
    /// bank (world plane), each at its own plane's offset (the statue's fire moves with the mid plane), culled to the
    /// visible width.
    private static func frameLights(sources: [(source: LightSource, plane: Plane)], ambient: AmbientSample,
                                    bankEdgeX: Double, animTime: Double, options: FrameOptions,
                                    geometry: Geometry) -> [FrameLight] {
        let bank = DarknessBank(edgeX: bankEdgeX)
        let torch = Double(ambient.torchStrength)
        var list: [FrameLight] = []
        for (source, plane) in sources {
            var radius = source.radius
            if plane == .world && bank.contains(x: source.x) { radius *= DarknessBank.radiusScale }
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
            let centreX = source.x - geometry.whole(plane)
            guard geometry.isVisible(left: centreX - radius, width: 2 * radius) else { continue }
            let centreY = Double(geometry.groundRow) - source.y
            let circle = SIMD4<Float>(Float(centreX), Float(centreY), Float(radius), Float(intensity))
            let rgba = SIMD4<Float>(color.x, color.y, color.z, 0)
            list.append(FrameLight(circle: circle, color: rgba, ellipseY: Float(LightField.ellipseY), kind: source.kind,
                                   plane: plane))
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

    /// Creatures (by the game's rule, M2b review: lit, as painted; unlit at night, an opaque dark body with its glow
    /// strip and a moonlight rim, never the eye dots or translucent ghosts "Not a copy" forbids), archers, citizens and
    /// the king last (his lantern glass from the dusk), in device pixels.
    private static func actorInstances(scene: PlaceholderScene, field: LightField, ambient: AmbientSample,
                                       animTime: Double, camera: Camera, options: FrameOptions,
                                       geometry: Geometry) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let white = SIMD4<Float>(1, 1, 1, 1)
        let night = min(1, max(0, ambient.torchStrength))
        let unlitValue = 1 - (1 - EntityFrames.unlitValue) * night

        for actor in scene.actors {
            let sprite = actor.kind.sprite
            let frame = actor.kind.idleBase + idleFrame(time: animTime + actor.phase, frames: sprite.frameCount)
            let flipped = actor.facing < 0
            if actor.kind.isCreature {
                let lit = field.isLit(x: actor.x, y: actor.litY)
                let rect = actorRect(sprite: sprite, x: actor.x, y: actor.y, camera: camera, options: options,
                                     geometry: geometry)
                guard isOnScreen(rect, geometry: geometry) else { continue }
                let value: Float = lit ? 1 : unlitValue
                list.append(ActorInstance(sprite: sprite, frame: frame, rect: rect,
                                          tint: SIMD4<Float>(value, value, value, 1), flipped: flipped,
                                          isEmissive: false, isLit: lit, lightCap: EntityFrames.creatureLightCap,
                                          moonRim: lit ? 0 : EntityFrames.unlitRim * night))
                if let glow = EntityFrames.glowStrip(sprite) {
                    list.append(ActorInstance(sprite: glow, frame: frame, rect: rect, tint: white, flipped: flipped,
                                              isEmissive: true, isLit: lit))
                }
            } else {
                let rect = actorRect(sprite: sprite, x: actor.x, y: actor.y, camera: camera, options: options,
                                     geometry: geometry)
                if isOnScreen(rect, geometry: geometry) {
                    let lit = field.isLit(x: actor.x, y: actor.litY)
                    list.append(ActorInstance(sprite: sprite, frame: frame, rect: rect, tint: white,
                                              flipped: flipped, isEmissive: false, isLit: lit))
                }
            }
        }

        let king = scene.king
        let kingFrame = kingFrameIndex(king: king, animTime: animTime)
        let kingRect = actorRect(sprite: .king, x: king.x, y: 0, camera: camera, options: options, geometry: geometry)
        if isOnScreen(kingRect, geometry: geometry) {
            let lit = field.isLit(x: king.x, y: king.litY)
            list.append(ActorInstance(sprite: .king, frame: kingFrame, rect: kingRect, tint: white,
                                      flipped: king.facing < 0, isEmissive: false, isLit: lit))
            if night >= 0.3 {
                let glass = 0.6 + 0.4 * (night - 0.3) / 0.7
                list.append(ActorInstance(sprite: .kingGlow, frame: kingFrame, rect: kingRect,
                                          tint: SIMD4<Float>(glass, glass, glass, 1), flipped: king.facing < 0,
                                          isEmissive: true, isLit: lit))
            }
        }
        return list
    }

    /// Idle animation at two frames per second.
    static func idleFrame(time: Double, frames: Int) -> Int {
        let count = max(1, min(2, frames))
        let step = Int((time * 2).rounded(.down))
        return ((step % count) + count) % count
    }

    /// The king's frame (SPRITES.md): idle 6 ... 7 standing, walk 0 ... 5 by distance (one frame per 7 game px), so
    /// his feet match the ground at any speed. The distance is measured along his facing, so the mirrored sprite walking left
    /// plays the cycle forward too (no moonwalk).
    static func kingFrameIndex(king: KingState, animTime: Double) -> Int {
        guard king.isWalking else { return 6 + idleFrame(time: animTime, frames: 2) }
        let walkStep = Int((king.x * Double(king.facing) / 7).rounded(.down))
        return ((walkStep % 6) + 6) % 6
    }

    /// An actor's quad in device pixels: its anchor (bottom centre) is `width / 2` whole game pixels from the left edge,
    /// so snapped actors stay on the world grid; its texels are s × s blocks.
    private static func actorRect(sprite: SpriteID, x: Double, y: Double, camera: Camera, options: FrameOptions,
                                  geometry: Geometry) -> SIMD4<Float> {
        let scale = geometry.scale
        let size = sprite.size
        let anchor = camera.deviceX(worldX: x, scale: scale, mode: options.actorMode)
        let width = size.width * scale
        let height = size.height * scale
        let left = anchor - (size.width / 2) * scale
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
