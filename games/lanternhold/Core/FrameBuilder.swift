import Foundation

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
        /// Look 2's weather at this moment (`WeatherSample.clear` in look 1).
        let weather: WeatherSample

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
        // The weather belongs to look 2 and to the picture alone: nothing of the simulation reads it.
        let weather = options.look == .two ? options.weather : WeatherSample.clear
        let geometry = Geometry(scale: scale,
                                targetWidth: pixelScale.targetWidth,
                                targetHeight: targetHeight,
                                groundRow: Camera.groundRow(targetHeight: targetHeight),
                                groundDeviceY: Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                                    scale: scale),
                                physicalWidth: pixelScale.physicalWidth,
                                offsets: camera.offsets(scale: scale),
                                focusX: camera.focusX,
                                weather: weather)
        let hour = clock.hour
        let ambient = Weather.apply(weather, to: AmbientRamp.sample(at: hour, look: options.look))
        let animTime = options.flickerTime ?? clock.elapsed
        let sources = entities?.lights ?? scene.sceneLights()
        let rains = options.look == .two && weather.rain > 0 && !options.reduceMotion
        let bankEdgeX = scene.bankEdge(hour: hour)
        // The Gloom's fog belongs to look 2 and to the picture alone, like the weather.
        let gloom = options.look == .two && options.effects.fog ? options.gloom : nil
        // While the fog is up, the bank's old wall of night is not drawn: the fog bank stands in its place.
        let fogUp = gloom?.presence(hour: hour) ?? 0
        let wall = Float(1 - fogUp)
        // The fires of the lines cut their holes into the fog.
        var clearings: [GloomFog.Clearing] = []
        if gloom != nil, fogUp > 0 {
            for item in sources where item.plane == .world {
                if let clearing = GloomFog.clearing(of: item.source, torch: Double(ambient.torchStrength),
                                                    bankEdge: bankEdgeX) {
                    clearings.append(clearing)
                }
            }
        }

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
                if let gloom, fogUp > 0 {
                    // The eyes in the bank's heart, behind everything that stands on the lane.
                    let eyes = gloomEyeTiles(gloom, edgeX: bankEdgeX, hour: hour, clearings: clearings,
                                             animTime: animTime, reduceMotion: options.reduceMotion,
                                             geometry: geometry)
                        + gloomEyes(gloom, edgeX: bankEdgeX, hour: hour, clearings: clearings, animTime: animTime,
                                    reduceMotion: options.reduceMotion, geometry: geometry)
                    for item in eyes {
                        glow.add(item)
                    }
                }
            }
            while next < ordered.count && ordered[next].plane == plane {
                addProp(ordered[next], ambient: ambient, hour: hour, animTime: animTime, options: options,
                        geometry: geometry, sprites: &planeSprites, glow: &glow)
                next += 1
            }
            if rains && plane == .near {
                planeSprites[plane.rawValue] += rainStreaks(depth: 0, animTime: animTime, ambient: ambient,
                                                            geometry: geometry)
            }
            if rains && plane == .foreground {
                planeSprites[plane.rawValue] += rainStreaks(depth: 2, animTime: animTime, ambient: ambient,
                                                            geometry: geometry)
            }
            if plane == .world {
                if options.look == .two {
                    planeSprites[plane.rawValue] += smoke(props: ordered, animTime: animTime,
                                                          reduceMotion: options.reduceMotion, geometry: geometry)
                    planeSprites[plane.rawValue] += steam(sources: sources, geometry: geometry)
                }
                if rains {
                    // Under the bank's tiles: the dark hides the rain that falls into it.
                    planeSprites[plane.rawValue] += rainSplashes(animTime: animTime, ambient: ambient,
                                                                 geometry: geometry)
                    planeSprites[plane.rawValue] += rainStreaks(depth: 1, animTime: animTime, ambient: ambient,
                                                                geometry: geometry)
                }
                for item in entities?.emissives(worldWhole: geometry.whole(.world), groundRow: geometry.groundRow,
                                                targetWidth: geometry.targetWidth) ?? [] {
                    glow.add(item)
                }
                if wall > 0.01 {
                    for tile in bankTiles(edgeX: bankEdgeX, geometry: geometry, alpha: wall) {
                        // A wall that is half gone hides no glow.
                        if wall >= 0.5 {
                            glow.occlude(tile, plane: .world)
                        }
                        planeSprites[plane.rawValue].append(tile)
                    }
                }
                if options.look == .two {
                    if wall > 0.01 {
                        for item in bankGlow(edgeX: bankEdgeX, geometry: geometry, animTime: animTime,
                                             reduceMotion: options.reduceMotion, strength: wall) {
                            glow.add(item)
                        }
                    }
                    for item in fireflies(hour: hour, animTime: animTime, reduceMotion: options.reduceMotion,
                                          geometry: geometry) {
                        glow.add(item)
                    }
                }
            }
        }
        let emissives = skyEmissives(ambient: ambient, hour: hour, geometry: geometry) + glow.items

        var fog: [FogLayer] = []
        if options.effects.fog {
            // The wind carries the fog and the mist (`WeatherSample.travel`, 0 in clear air).
            let layers = fogLayers(ambient: ambient, animTime: animTime + weather.travel,
                                   reduceMotion: options.reduceMotion,
                                   look: options.look)
            for layer in layers {
                let tiles = options.look == .two ? fogBankTiles(layer: layer, geometry: geometry)
                                                 : fogTiles(layer: layer, geometry: geometry)
                planeSprites[layer.plane.rawValue].append(contentsOf: tiles)
            }
            fog = layers
            if let gloom, fogUp > 0 {
                // In front of the hour's own fog on both fog planes. The strips are painted in the night's own
                // colours: the lift the shader gives the hour's fog is taken out of their tint.
                let value = 1 / max(1, Look2.fogBrightness(ambient))
                for strip in gloomStrips {
                    planeSprites[strip.plane.rawValue] += gloomSlices(gloom, strip: strip, edgeX: bankEdgeX,
                                                                      hour: hour, value: value,
                                                                      clearings: clearings, animTime: animTime,
                                                                      reduceMotion: options.reduceMotion,
                                                                      geometry: geometry)
                }
                planeSprites[Plane.fogB.rawValue] += gloomWisps(gloom, edgeX: bankEdgeX, hour: hour, value: value,
                                                                clearings: clearings, animTime: animTime,
                                                                reduceMotion: options.reduceMotion,
                                                                geometry: geometry)
            }
        }

        let lights = frameLights(sources: sources, ambient: ambient,
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
            desc.rain = Float(weather.rain)
            desc.wetness = Float(weather.wetness)
        }
        return desc
    }

    // MARK: - Sky

    /// Stars, the moon and the sun on the sky plane (parallax 0: target pixels are screen pixels).
    private static func skyEmissives(ambient: AmbientSample, hour: Double, geometry: Geometry) -> [EmissiveInstance] {
        var list: [EmissiveInstance] = []
        let width = geometry.targetWidth
        let ground = geometry.groundRow
        // Clouds veil the moon and the sun (look 2's weather; 1 in clear air).
        let veil = Float(1 - 0.8 * geometry.weather.cover)

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
            let alpha = min(1, max(0, ambient.moonHeight * 3 + 0.3)) * veil
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
            let alpha = min(1, max(0, ambient.sunHeight * 5 + 0.5)) * veil
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
    /// The wind leans it (`smokeLean`; with Reduce Motion by the steady wind, without the gusts).
    private static func smoke(props: [Prop], animTime: Double, reduceMotion: Bool,
                              geometry: Geometry) -> [SpriteInstance] {
        let weather = geometry.weather
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
            let column = SpriteInstance(sprite: .d2Smoke, frame: 0, rect: rect, tint: look2SmokeTint,
                                        flipped: false)
            let wind = reduceMotion ? weather.mean : Weather.wind(at: chimney.x, weather, time: animTime)
            list += sheared(column, offset: Int((wind * smokeLean).rounded()), bands: 10, bend: false)
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
    private static func bankTiles(edgeX: Double, geometry: Geometry, alpha: Float = 1) -> [SpriteInstance] {
        let edge = edgeX.rounded(.down)
        let whole = geometry.whole(.world)
        let edgeSize = SpriteID.darknessEdge.size
        let bodySize = SpriteID.darknessBank.size
        let baseY = -Double(WorldLayout.groundRowsBelow)
        let white = SIMD4<Float>(1, 1, 1, alpha)
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

    /// Look 2 (SPRITES.md, ART-look2.md 11.5): the bank's cold eyes and dim embers, one frame of `darknessBankGlow`
    /// over each body tile of the bank, drawn as it is: frame (tile index + time × 1.5) mod 4, with Reduce Motion the
    /// tile index mod 4. The tiles are counted from the bank's edge, as `bankTiles` lays them.
    private static func bankGlow(edgeX: Double, geometry: Geometry, animTime: Double,
                         reduceMotion: Bool, strength: Float = 1) -> [EmissiveInstance] {
        let whole = geometry.whole(.world)
        let size = SpriteID.darknessBankGlow.size
        let width = Double(size.width)
        let frames = SpriteID.darknessBankGlow.frameCount
        let step = reduceMotion ? 0 : Int((animTime * 1.5).rounded(.down))
        let top = geometry.top(y: -Double(WorldLayout.groundRowsBelow), height: Double(size.height))
        var list: [EmissiveInstance] = []
        var x = edgeX.rounded(.down) - Double(SpriteID.darknessEdge.size.width) - width
        var index = 0
        while x > -width {
            let left = x - whole
            if geometry.isVisible(left: left, width: width) {
                let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
                list.append(EmissiveInstance(sprite: .darknessBankGlow, plane: .world, rect: rect,
                                             color: SIMD4<Float>(strength, strength, strength, 1),
                                             frame: (index + step) % frames))
            }
            x -= width
            index += 1
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
            // Under cloud the sun casts less of a shadow (look 2's weather; × 1 in clear air).
            let strength = sunShadowAlpha(shadow, ambient: ambient, hour: hour) * alpha * prop.alpha
                * Float(1 - geometry.weather.cover)
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
        // The wind sways a tree's crown and the foreground's plants; the glow's occluder stays the whole sprite.
        let lean = hidesGlow ? swayLean(prop, animTime: animTime, options: options, geometry: geometry) : 0
        sprites[prop.plane.rawValue] += sheared(sprite, offset: lean, bands: 6, bend: true)

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
            let flicker = Flicker.sample(seed: seed, time: animTime * part.flickerPace,
                                         reduceMotion: options.reduceMotion)
            // A fire's own flicker untouched (look 1's golden frames), a share of it for a lit room.
            let swing = Float(flicker.intensity)
            strength *= part.flickerAmount == 1 ? swing : 1 + (swing - 1) * part.flickerAmount
        }
        guard strength > 0.01 else { return nil }
        let dx = prop.flipped ? Double(prop.width) - part.dx - Double(size.width) : part.dx
        let x = left + dx
        let top = geometry.top(y: bottom + part.dy, height: Double(size.height))
        let rect = SIMD4<Float>(Float(x), Float(top), Float(size.width), Float(size.height))
        let rgb = part.color * strength
        let color = SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)
        return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color,
                                flipped: part.mirrors && prop.flipped)
    }

    // MARK: - Fireflies

    /// Where the valley's fireflies stand (docs/PORT-look2.md 2.6, ART-look2.md 13.8): the left edge of each patch
    /// of `d2Fireflies` in world pixels and its rows above the lane. The mock's two and two more toward the river.
    static let fireflyPatches: [(x: Double, y: Double)] = [(2610, 8), (2870, 6), (3110, 6), (3390, 9)]
    /// The hours they fly: in from 18:30, out by 21:00, half an hour each way.
    static let fireflyHours = 18.5...21.0

    /// How brightly the fireflies glow (0: none): at dusk only, none in the rain, none in a wind above 0.6.
    static func fireflyStrength(hour: Double, weather: WeatherSample) -> Double {
        guard fireflyHours.contains(hour) else { return 0 }
        let rise = min(1, (hour - fireflyHours.lowerBound) / 0.5)
        let fall = min(1, (fireflyHours.upperBound - hour) / 0.5)
        let dry = 1 - min(1, weather.rain * 4)
        let calm = 1 - min(1, max(0, (abs(weather.mean) - 0.45) / 0.15))
        return max(0, min(rise, fall) * dry * calm)
    }

    /// Polish after round 2, the fireflies at phone size: a fly is one game pixel, so each patch is drawn brighter
    /// than white (`fireflyGain`: the bloom gives it a halo) and four more times one pixel off at `fireflyHalo` of
    /// its glow: a bright dot in a soft cross, three game pixels wide.
    static let fireflyGain = 2.2
    static let fireflyHalo = 0.28
    static let fireflyDots: [(dx: Double, dy: Double, share: Double)] = [
        (0, 0, 1), (-1, 0, fireflyHalo), (1, 0, fireflyHalo), (0, -1, fireflyHalo), (0, 1, fireflyHalo),
    ]

    /// The fireflies as glow: each patch twice, the second mirrored and a few pixels off, the two blinking against
    /// each other, both drifting on a slow figure of eight in whole pixels. With Reduce Motion they stand and only
    /// breathe. A pure function of the hour, the time and the weather; no light quads (the cap is for fires).
    private static func fireflies(hour: Double, animTime: Double, reduceMotion: Bool,
                                  geometry: Geometry) -> [EmissiveInstance] {
        let strength = fireflyStrength(hour: hour, weather: geometry.weather)
        guard strength > 0.01 else { return [] }
        let size = SpriteID.d2Fireflies.size
        let width = Double(size.width)
        let whole = geometry.whole(.world)
        var list: [EmissiveInstance] = []
        for (index, patch) in fireflyPatches.enumerated() {
            for copy in 0..<2 {
                let phase = Double(index) * 1.7 + Double(copy) * Double.pi
                let dx = reduceMotion ? 0 : (sin(animTime * 0.23 + phase) * 5).rounded()
                let dy = reduceMotion ? 0 : (sin(animTime * 0.46 + phase * 2) * 2).rounded()
                let blink = 0.6 + 0.4 * sin(animTime * (reduceMotion ? 0.8 : 2.4) + phase)
                let left = patch.x + Double(copy) * 23 + dx - whole
                guard geometry.isVisible(left: left, width: width) else { continue }
                let top = geometry.top(y: patch.y + Double(copy) * 4 + dy, height: Double(size.height))
                for dot in fireflyDots {
                    let rgb = GamePalette.fireGold * Float(strength * blink * fireflyGain * dot.share)
                    let rect = SIMD4<Float>(Float(left + dot.dx), Float(top + dot.dy), Float(size.width),
                                            Float(size.height))
                    list.append(EmissiveInstance(sprite: .d2Fireflies, plane: .world, rect: rect,
                                                 color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1), flipped: copy == 1))
                }
            }
        }
        return list
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

    // MARK: - The Gloom's fog (look 2)

    /// One strip of the Gloom's fog (SPRITES.md "The Gloom's fog"): its plane, its painting (frame 0 the body that
    /// repeats, frame 1 the leading face), where its bottom stands above the ground line, the share of the fog's way
    /// its own front has come (the tall bank stays near the darkness, the creeping fog leads), and how its front
    /// breathes: pixels either way, seconds a breath, where in the breath it starts.
    struct GloomStrip: Sendable, Equatable {
        var plane: Plane
        var sprite: SpriteID
        var y: Double
        var share: Double
        var sway: Double
        var period: Double
        var phase: Double
    }

    /// Behind the play plane the fog bank, in front of the actors the veil and the creeping fog. On the first night
    /// their fronts stand 64, 105 and 150 pixels past the bank's edge, close to where the art lane laid them; a hard
    /// night carries them further up the Throat.
    static let gloomStrips = [
        GloomStrip(plane: .fogA, sprite: .gloomFogBack, y: 0, share: 0.43, sway: 3, period: 9, phase: 0),
        GloomStrip(plane: .fogB, sprite: .gloomFogMid, y: 0, share: 0.7, sway: 6, period: 7, phase: 0.33),
        GloomStrip(plane: .fogB, sprite: .gloomFogFront, y: -8, share: 1, sway: 10, period: 5, phase: 0.67),
    ]
    /// The fog is drawn in slices this wide, each with the hole a fire cuts where it stands.
    static let gloomSlice = 16
    /// The eyes glow a little over white, so the bloom catches them at phone size.
    static let gloomEyeGain: Float = 1.4
    /// The painted eyes' tiles are laid leftward from this far behind the bank's edge.
    static let gloomEyeInset = 32.0

    /// The world x of a strip's front at this moment: its share of the fog's way past the bank's edge, breathing
    /// (never with Reduce Motion).
    static func gloomFront(_ gloom: GloomFog, strip: GloomStrip, edgeX: Double, hour: Double, animTime: Double,
                           reduceMotion: Bool) -> Double {
        let way = gloom.front(bankEdge: edgeX, hour: hour) - edgeX
        let breath = reduceMotion ? 0 : strip.sway * sin(2 * Double.pi * (animTime / strip.period + strip.phase))
        return min(GloomFog.maxFront, (edgeX + strip.share * way + breath).rounded())
    }

    /// One strip of the Gloom's fog across the screen, at the lane's own parallax: the leading face ends at the
    /// strip's front, the body repeats behind it to the screen's left end. It is cut into slices of `gloomSlice`
    /// pixels, each drawn with the fog's presence less the hole a fire cuts there. `value` takes the lift out that
    /// the shader gives the hour's fog, so the painting keeps its own colours.
    private static func gloomSlices(_ gloom: GloomFog, strip: GloomStrip, edgeX: Double, hour: Double, value: Float,
                                    clearings: [GloomFog.Clearing], animTime: Double, reduceMotion: Bool,
                                    geometry: Geometry) -> [SpriteInstance] {
        let world = geometry.whole(.world)
        let front = gloomFront(gloom, strip: strip, edgeX: edgeX, hour: hour, animTime: animTime,
                               reduceMotion: reduceMotion)
        let size = strip.sprite.size
        let tile = Double(size.width)
        let slice = Double(gloomSlice)
        let top = geometry.top(y: strip.y, height: Double(size.height))
        let whole = gloom.presence(hour: hour) * gloom.paintCover
        var list: [SpriteInstance] = []
        var tileLeft = front - tile - world
        var face = true
        // Nothing of it in view while the camera looks at the castle or the valley.
        while tileLeft + tile >= -1 {
            if geometry.isVisible(left: tileLeft, width: tile) {
                for k in 0..<(size.width / gloomSlice) {
                    let left = tileLeft + Double(k) * slice
                    guard geometry.isVisible(left: left, width: slice) else { continue }
                    let x = left + slice / 2 + world
                    let cover = whole * (1 - GloomFog.hole(x: x, clearings: clearings))
                    guard cover > 0.012 else { continue }
                    let rect = SIMD4<Float>(Float(left), Float(top), Float(gloomSlice), Float(size.height))
                    let source = SIMD4<Float>(Float(k * gloomSlice), 0, Float(gloomSlice), Float(size.height))
                    list.append(SpriteInstance(sprite: strip.sprite, frame: face ? 1 : 0, rect: rect,
                                               tint: SIMD4<Float>(value, value, value, Float(min(1, cover))),
                                               flipped: false, source: source))
                }
            }
            tileLeft -= tile
            face = false
        }
        return list
    }

    /// The shreds that tear off the creeping fog's nose, drawn with it (none with Reduce Motion). They hang on the
    /// front's resting place, so its breath does not drag them.
    private static func gloomWisps(_ gloom: GloomFog, edgeX: Double, hour: Double, value: Float,
                                   clearings: [GloomFog.Clearing], animTime: Double, reduceMotion: Bool,
                                   geometry: Geometry) -> [SpriteInstance] {
        guard !reduceMotion, let strip = gloomStrips.last else { return [] }
        let size = SpriteID.gloomWisp.size
        let width = Double(size.width)
        let world = geometry.whole(.world)
        let front = gloomFront(gloom, strip: strip, edgeX: edgeX, hour: hour, animTime: animTime, reduceMotion: true)
        let whole = gloom.presence(hour: hour) * gloom.paintCover
        var list: [SpriteInstance] = []
        for wisp in GloomFog.wisps(time: animTime) {
            let left = front + wisp.offset - world
            guard geometry.isVisible(left: left, width: width) else { continue }
            let cover = whole * (1 - GloomFog.hole(x: left + width / 2 + world, clearings: clearings))
            guard cover > 0.012 else { continue }
            let top = geometry.top(y: wisp.y, height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .gloomWisp, frame: wisp.frame, rect: rect,
                                       tint: SIMD4<Float>(value, value, value, Float(min(1, cover))),
                                       flipped: false))
        }
        return list
    }

    /// The painted eyes in the bank's heart (`gloomFogEyes`, glow only): tiles laid leftward from a little behind
    /// the bank's edge to the screen's left end, each stepping through the four frames on its own beat (standing
    /// with Reduce Motion), dimmed where a fire clears the fog.
    private static func gloomEyeTiles(_ gloom: GloomFog, edgeX: Double, hour: Double,
                                      clearings: [GloomFog.Clearing], animTime: Double, reduceMotion: Bool,
                                      geometry: Geometry) -> [EmissiveInstance] {
        let size = SpriteID.gloomFogEyes.size
        let tile = Double(size.width)
        let world = geometry.whole(.world)
        let frames = SpriteID.gloomFogEyes.frameCount
        let step = reduceMotion ? 0 : Int((max(0, animTime) * 1.5).rounded(.down))
        let presence = gloom.presence(hour: hour)
        let top = geometry.top(y: 0, height: Double(size.height))
        var list: [EmissiveInstance] = []
        var index = 0
        var left = edgeX.rounded() - gloomEyeInset - tile - world
        while left + tile >= -1 {
            if geometry.isVisible(left: left, width: tile) {
                let strength = presence * (1 - GloomFog.hole(x: left + tile / 2 + world, clearings: clearings))
                if strength > 0.02 {
                    let value = Float(strength)
                    let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
                    list.append(EmissiveInstance(sprite: .gloomFogEyes, plane: .world, rect: rect,
                                                 color: SIMD4<Float>(value, value, value, 1),
                                                 frame: (index + step) % frames))
                }
            }
            index += 1
            left -= tile
        }
        return list
    }

    /// The cold eyes that open and close in the fog as glow on the world plane, dimmed where a fire clears it.
    private static func gloomEyes(_ gloom: GloomFog, edgeX: Double, hour: Double, clearings: [GloomFog.Clearing],
                                  animTime: Double, reduceMotion: Bool, geometry: Geometry) -> [EmissiveInstance] {
        let size = SpriteID.eyeGlints.size
        let whole = geometry.whole(.world)
        var list: [EmissiveInstance] = []
        for eyes in gloom.eyes(bankEdge: edgeX, hour: hour, time: animTime, reduceMotion: reduceMotion) {
            let left = eyes.x - whole
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
            let seen = eyes.strength * (1 - GloomFog.hole(x: eyes.x, clearings: clearings))
            guard seen > 0.02 else { continue }
            let top = geometry.top(y: eyes.y, height: Double(size.height))
            let rgb = GloomFog.eyeColor * (Float(seen) * gloomEyeGain)
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(EmissiveInstance(sprite: .eyeGlints, plane: .world, rect: rect,
                                         color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)))
        }
        return list
    }

    // MARK: - Weather (look 2)

    /// Sprites the wind sways: the trees and the foreground's plants.
    private static let swaying: Set<SpriteID> = [.firA, .firB, .firC, .firD, .deadTreeA, .deadTreeB, .linden, .poplar,
                                                 .appleTree, .willow, .lindenB, .lindenC, .poplarB, .poplarC,
                                                 .appleTreeB, .appleTreeC, .willowB, .willowC, .d2FgFerns,
                                                 .d2FgMeadow, .d2FgReeds]

    /// The rain's three depths (docs/PORT-look2.md 3.4): the plane, how fast it falls (game px/s), how many at full
    /// rain and its alpha (under 0.5, so no streak is a ledge that catches the sky).
    static let rainDepths: [(plane: Plane, speed: Double, count: Int, alpha: Float)] = [
        (.near, 150, 110, 0.30), (.world, 220, 70, 0.40), (.foreground, 320, 28, 0.45),
    ]
    /// A streak's sideways run per row fallen, by slant (as `PlaceholderWeather.streakRuns` paints them).
    static let rainSlopes = [0.0, 0.27, 0.47]
    /// The slant of the rain: still air, wind, strong wind (by the steady wind, so gusts do not make it jump).
    static func rainSlant(_ weather: WeatherSample) -> Int {
        let force = abs(weather.mean)
        return force < 0.2 ? 0 : (force < 0.6 ? 1 : 2)
    }
    /// How many of `full` fall in a rain of this strength: by its root, so a light rain (0.4) is still rain on a
    /// phone (round lh-l2-3a: at 0.6 a count in proportion read as a few stray streaks).
    static func rainCount(_ full: Int, rain: Double) -> Int {
        Int((Double(full) * max(0, min(1, rain)).squareRoot()).rounded())
    }
    /// Polish after round 2, the rain over a bright scene: a pale streak before an overcast day sky or a sunlit
    /// wall is the scene's own tone and is lost. So the brighter the air, the darker the rain falls: slate by day
    /// (`rainDayShade`, a little denser), pale as painted from dusk on, where the fires light it.
    static let rainDayShade = SIMD3<Float>(0.34, 0.40, 0.54)
    static let rainDayAlpha: Float = 1.08
    /// How much of the day's shade the rain takes in this air (0 from dusk through the night ... 1 by day).
    static func rainShade(_ ambient: AmbientSample) -> Float {
        Float(AmbientRamp.smoothstep(Double((ambient.ambientIntensity - 0.26) / 0.34)))
    }
    /// A streak's or a splash's tint in this air; its alpha stays under 0.5 (no streak is a ledge).
    static func rainTint(alpha: Float, ambient: AmbientSample) -> SIMD4<Float> {
        let shade = rainShade(ambient)
        let rgb = SIMD3<Float>(1, 1, 1) + (rainDayShade - SIMD3<Float>(1, 1, 1)) * shade
        return SIMD4<Float>(rgb.x, rgb.y, rgb.z, min(0.49, alpha * (1 + (rainDayAlpha - 1) * shade)))
    }
    /// Splashes on the lane at full rain, and a splash's seconds.
    static let rainSplashCount = 24
    static let rainSplashTime = 0.3
    /// The steam over a fire in the rain: the lower rows of `d2Smoke`, its alpha at full rain.
    static let steamRows = 28
    static let steamAlpha: Float = 0.3
    /// The smoke's top leans this many pixels in a wind of 1.
    static let smokeLean = 12.0

    private static func unit(_ hash: UInt64) -> Double {
        Double(hash >> 11) * 0x1.0p-53
    }

    /// How far the wind pushes a prop's top (whole pixels): only the trees and plants of the near, world and
    /// foreground planes, never with Reduce Motion.
    private static func swayLean(_ prop: Prop, animTime: Double, options: FrameOptions, geometry: Geometry) -> Int {
        let weather = geometry.weather
        guard weather != .clear, !options.reduceMotion, swaying.contains(prop.sprite),
              prop.plane == .near || prop.plane == .world || prop.plane == .foreground else { return 0 }
        return Weather.swayOffset(x: prop.x, weather, time: animTime)
    }

    /// `sprite` as `bands` bands of rows, the top one shifted by `offset` pixels, the bottom one not at all, the ones
    /// between in a line (or, bent, by the square: a trunk stands and a crown moves). Bands with the same shift are
    /// one quad. A sprite that is not drawn whole stays as it is.
    static func sheared(_ sprite: SpriteInstance, offset: Int, bands: Int, bend: Bool) -> [SpriteInstance] {
        let size = sprite.sprite.size
        let rows = size.height
        guard offset != 0, bands > 1, rows >= bands, sprite.source == nil, Int(sprite.rect.z) == size.width,
              Int(sprite.rect.w) == rows else { return [sprite] }
        var list: [SpriteInstance] = []
        var start = 0
        var shift = offset
        for band in 1...bands {
            var next = 0
            if band < bands {
                let share = 1 - Double(band) / Double(bands - 1)
                next = Int((Double(offset) * (bend ? share * share : share)).rounded())
                if next == shift { continue }
            }
            let end = rows * band / bands
            var part = sprite
            part.rect = SIMD4<Float>(sprite.rect.x + Float(shift), sprite.rect.y + Float(start), sprite.rect.z,
                                     Float(end - start))
            part.source = SIMD4<Float>(0, Float(start), sprite.rect.z, Float(end - start))
            list.append(part)
            start = end
            shift = next
        }
        return list
    }

    /// The rain's streaks on one depth's plane: each a pure function of its index and the time. It falls from above
    /// the screen to the plane's floor (the ground behind the near trees, the lane, the screen's bottom edge), then
    /// starts again in another column; the columns belong to the plane's picture, so the rain stays in the world
    /// when the camera moves.
    private static func rainStreaks(depth: Int, animTime: Double, ambient: AmbientSample,
                                    geometry: Geometry) -> [SpriteInstance] {
        let weather = geometry.weather
        let entry = rainDepths[depth]
        let count = rainCount(entry.count, rain: weather.rain)
        guard count > 0 else { return [] }
        let size = SpriteID.rainStreak.size
        let slant = rainSlant(weather)
        let slope = rainSlopes[slant] * (weather.mean < 0 ? -1 : 1)
        let lowest: Double
        switch entry.plane {
        case .foreground: lowest = Double(geometry.targetHeight)
        case .world: lowest = Double(geometry.groundRow + 3)
        default: lowest = Double(geometry.groundRow - 8)
        }
        let fall = lowest + Double(size.height)
        let reach = abs(slope) * fall
        let span = Double(geometry.targetWidth) + reach
        let whole = geometry.whole(entry.plane)
        let tint = rainTint(alpha: entry.alpha, ambient: ambient)
        let key = SeededRandom.hash(weather.gustSeed, Int64(depth + 1))
        var list: [SpriteInstance] = []
        for index in 0..<count {
            let progress = animTime * entry.speed / fall + unit(SeededRandom.hash(key, Int64(index)))
            let cycle = progress.rounded(.down)
            let y = (progress - cycle) * fall - Double(size.height)
            let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
            let column = unit(SeededRandom.hash(SeededRandom.hash(key, turn), Int64(index))) * span
            var x = (column - whole).truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            x += slope * y - (slope > 0 ? reach : 0)
            let rect = SIMD4<Float>(Float(x.rounded(.down)), Float(y.rounded(.down)), Float(size.width),
                                    Float(size.height))
            list.append(SpriteInstance(sprite: .rainStreak, frame: depth * 3 + slant, rect: rect, tint: tint,
                                       flipped: slope < 0))
        }
        return list
    }

    /// The splashes where the rain meets the lane: three frames each, then the next one somewhere else.
    private static func rainSplashes(animTime: Double, ambient: AmbientSample,
                                     geometry: Geometry) -> [SpriteInstance] {
        let weather = geometry.weather
        let count = rainCount(rainSplashCount, rain: weather.rain)
        guard count > 0 else { return [] }
        let size = SpriteID.rainSplash.size
        let width = Double(geometry.targetWidth)
        let whole = geometry.whole(.world)
        let key = SeededRandom.hash(weather.gustSeed, 7)
        let tint = rainTint(alpha: 0.45, ambient: ambient)
        var list: [SpriteInstance] = []
        for index in 0..<count {
            let progress = animTime / rainSplashTime + unit(SeededRandom.hash(key, Int64(index)))
            let cycle = progress.rounded(.down)
            let frame = min(2, Int((progress - cycle) * 3))
            let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
            let column = unit(SeededRandom.hash(SeededRandom.hash(key, turn), Int64(index))) * width
            var x = (column - whole).truncatingRemainder(dividingBy: width)
            if x < 0 { x += width }
            let top = geometry.top(y: -Double(1 + index % 4), height: Double(size.height))
            let rect = SIMD4<Float>(Float(x.rounded(.down)), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .rainSplash, frame: frame, rect: rect, tint: tint, flipped: false))
        }
        return list
    }

    /// A wisp of steam over each large fire of the world plane while it rains (at most eight): the smoke's lower
    /// rows, pale, a veil that hides no glow. It stands with Reduce Motion.
    private static func steam(sources: [(source: LightSource, plane: Plane)], geometry: Geometry) -> [SpriteInstance] {
        let rain = Float(geometry.weather.rain)
        guard rain > 0 else { return [] }
        let size = SpriteID.d2Smoke.size
        let rows = min(steamRows, size.height)
        let tint = SIMD4<Float>(0.80, 0.82, 0.86, steamAlpha * rain)
        var list: [SpriteInstance] = []
        for (source, plane) in sources where plane == .world && Weather.steams(source.kind) && source.intensity > 0 {
            guard list.count < 8 else { break }
            let left = (source.x - Double(size.width / 2) - geometry.whole(.world)).rounded(.down)
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
            let top = geometry.top(y: source.y + 2, height: Double(rows)).rounded(.down)
            var wisp = SpriteInstance(sprite: .d2Smoke, frame: 0,
                                      rect: SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(rows)),
                                      tint: tint, flipped: false)
            wisp.source = SIMD4<Float>(0, Float(size.height - rows), Float(size.width), Float(rows))
            list.append(wisp)
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
                let rain = geometry.weather.rain
                if rain > 0 && Weather.hisses(source.kind) {
                    // An open flame hisses in the rain: a little lower, its flicker wider.
                    intensity *= (1 - 0.12 * rain) * (1 + (flicker.intensity - 1) * (1 + 0.6 * rain))
                } else {
                    intensity *= flicker.intensity
                }
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
