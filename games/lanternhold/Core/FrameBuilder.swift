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
    /// World-2: the keep's glass glows at this share (it stands back, behind the curtain wall).
    static let keepGlass: Float = 0.72
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
            case .top:
                let bottom = Double(groundRow) - prop.y - Double(prop.height)
                // World rebuild: a backdrop anchored at the top (the cleft wall and its slit of sky) keeps its top
                // row at the screen's top on every phone; only the foreground's lips stop short of the statue.
                return prop.plane == .foreground ? max(bottom, FrameBuilder.lipLowestBottom) : bottom
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
        var ambient = Weather.apply(weather, to: AmbientRamp.sample(at: hour, look: options.look))
        if options.look == .two {
            // World rebuild, step world-2 (REVIEW-look-2.md 2.8, item 4): through the postern the picture turns warm
            // over world 2330 to 2530, the reveal of the valley (`SceneLayout.valleyWarmth`); fix round 2 (the critic's
            // high 9): its ambient and fog a warm step too (`SceneLayout.valleyWarmed`).
            ambient = SceneLayout.valleyWarmed(ambient, focus: camera.focusX)
        }
        let animTime = options.flickerTime ?? clock.elapsed
        let sources = entities?.lights ?? scene.sceneLights()
        // Build 3 step 2 (the two rains, lane 3): with Reduce Motion the rain's and the ash's forms stay where they
        // stood at one moment; step 3 (the director's call 5): neither hangs frozen, a third of them fade in and out in
        // place (`rainPulseAlpha`). The trees stand as before.
        let rains = options.look == .two && weather.rain > 0
        let bankEdgeX = scene.bankEdge(hour: hour)
        // Step 3 (the director's call 2): where the rain catches a light at night (`rainLightSpots`).
        let rainLights = rains ? rainLightSpots(sources: sources, ambient: ambient, geometry: geometry) : []
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
        // Build 3 step 2: water east of the outermost standing wall, ash west of it (`RainLook`).
        let rainSeam = rains ? RainLook.seam(ordered) : Realm.wallX[0]
        // World-3 fix round 2 (the critic's high 1): no eyes before a building, none over 60 rows (`EyeRules`).
        let eyeScreens = options.look == .two ? EyeRules.screens(ordered) : []
        var next = 0
        for plane in Plane.allCases {
            if plane == .mid && options.look == .two, let moon = wedgeMoon(ambient: ambient, geometry: geometry) {
                // World-2 fix round 1: the moon on the sky, behind the cleft's rock (`wedgeMoon`).
                glow.add(moon)
            }
            if plane == .world {
                let tiles = options.look == .two ? laneTiles(geometry: geometry) : groundTiles(geometry: geometry)
                for tile in tiles {
                    glow.occlude(tile, plane: .world)
                    planeSprites[plane.rawValue].append(tile)
                }
                if let gloom, fogUp > 0 {
                    // The eyes in the fog, behind everything that stands on the lane. (World rebuild, fix round 1:
                    // the painted eye tiles of the bank's heart are gone; with the bank's sheet lower they stood
                    // above it in rows, 64 px apart. The bank keeps its own eyes in the fog, `bankEyes`.)
                    for item in gloomEyes(gloom, edgeX: bankEdgeX, hour: hour, clearings: clearings,
                                          animTime: animTime, reduceMotion: options.reduceMotion, geometry: geometry,
                                          screens: eyeScreens) {
                        glow.add(item)
                    }
                }
            }
            while next < ordered.count && ordered[next].plane == plane {
                addProp(ordered[next], ambient: ambient, hour: hour, animTime: animTime, options: options,
                        geometry: geometry, sprites: &planeSprites, glow: &glow)
                next += 1
            }
            if plane == .world && options.look == .two,
               let streak = riverLanternStreak(props: ordered, ambient: ambient, geometry: geometry) {
                // World-3 fix round 1 (the critic's high 8): the far lantern's reflection, added after the world
                // plane's water so it lies on it.
                glow.add(streak)
            }
            if (plane == .near || plane == .world) && options.look == .two {
                // World rebuild, step world-2: the castle's chimneys smoke, the keep's in the near plane's picture
                // (moving with the mist band), the bakehouse's on the world plane.
                planeSprites[plane.rawValue] += castleSmoke(props: ordered, plane: plane, animTime: animTime,
                                                            reduceMotion: options.reduceMotion, geometry: geometry,
                                                            ambient: ambient, glow: &glow)
            }
            if plane == .mid && options.look == .two {
                // Fix round 1: the threads of water falling down the cleft wall, in front of it.
                planeSprites[plane.rawValue] += cleftWater(animTime: animTime, reduceMotion: options.reduceMotion,
                                                           geometry: geometry)
                // World-2 (the critic of world-1, look 3: "the warm graze paints the wall's foot as pale lilac drips"):
                // no band of glow along the wall's foot any more; the castle's fires warm the wall over the roofs as the
                // cleft wall's backdrop lights, pools where light really burns.
            }
            if rains && (plane == .near || plane == .foreground) {
                // Step 3: the near plane's depth and the foreground's; each flake's faint night copy and an ember's
                // point go into the emissive pass at once (the lane's props hide the near depth's, as they hide it).
                let depth = plane == .near ? 0 : 2
                planeSprites[plane.rawValue] += rainStreaks(depth: depth, animTime: animTime,
                                                            reduceMotion: options.reduceMotion, ambient: ambient,
                                                            seam: rainSeam, lights: rainLights, geometry: geometry,
                                                            glow: &glow)
                let ash = ashFlakes(depth: depth, animTime: animTime, reduceMotion: options.reduceMotion,
                                    ambient: ambient, seam: rainSeam, bankEdge: bankEdgeX, geometry: geometry)
                planeSprites[plane.rawValue] += ash.sprites
                for item in ash.glow {
                    glow.add(item)
                }
            }
            if plane == .world {
                // Step 3 (the critic's H1 (c)): the lane depth's flakes go under the bank's sheet, their night copies
                // and embers after it, so the ash is pale against the bank and never drawn dark into it.
                var ashGlow: [EmissiveInstance] = []
                if options.look == .two {
                    planeSprites[plane.rawValue] += smoke(props: ordered, animTime: animTime,
                                                          reduceMotion: options.reduceMotion, geometry: geometry)
                    planeSprites[plane.rawValue] += steam(sources: sources, geometry: geometry)
                }
                if rains {
                    // Under the bank's tiles: the dark hides the rain that falls into it.
                    planeSprites[plane.rawValue] += rainSplashes(animTime: animTime,
                                                                 reduceMotion: options.reduceMotion, ambient: ambient,
                                                                 seam: rainSeam, props: ordered, geometry: geometry)
                    planeSprites[plane.rawValue] += rainStreaks(depth: 1, animTime: animTime,
                                                                reduceMotion: options.reduceMotion, ambient: ambient,
                                                                seam: rainSeam, lights: rainLights,
                                                                geometry: geometry, glow: &glow)
                    let ash = ashFlakes(depth: 1, animTime: animTime, reduceMotion: options.reduceMotion,
                                        ambient: ambient, seam: rainSeam, bankEdge: bankEdgeX, geometry: geometry)
                    planeSprites[plane.rawValue] += ash.sprites
                    ashGlow = ash.glow
                }
                if options.look == .two && geometry.weather != .clear && !options.reduceMotion {
                    // Step 3 (part B): what a gust carries across the lane, east of the outermost standing wall.
                    planeSprites[plane.rawValue] += gustLeaves(props: ordered, animTime: animTime,
                                                               seam: rains ? rainSeam : RainLook.seam(ordered),
                                                               geometry: geometry)
                }
                for item in entities?.emissives(worldWhole: geometry.whole(.world), groundRow: geometry.groundRow,
                                                targetWidth: geometry.targetWidth) ?? [] {
                    glow.add(item)
                }
                if options.look == .two {
                    // World rebuild: the darkness bank's sheet on the lane's plane (it stands with the fog too).
                    for sheet in bankSheets where sheet.plane == .world {
                        let tint = bankTint(sheet.sprite, ambient: ambient)
                        for tile in bankSheetTiles(sheet, edgeX: bankEdgeX, tint: tint, animTime: animTime,
                                                   reduceMotion: options.reduceMotion, geometry: geometry) {
                            glow.occlude(tile, plane: .world)
                            planeSprites[plane.rawValue].append(tile)
                        }
                    }
                } else if wall > 0.01 {
                    for tile in bankTiles(edgeX: bankEdgeX, geometry: geometry, alpha: wall) {
                        // A wall that is half gone hides no glow.
                        if wall >= 0.5 {
                            glow.occlude(tile, plane: .world)
                        }
                        planeSprites[plane.rawValue].append(tile)
                    }
                }
                for item in ashGlow {
                    glow.add(item)
                }
                if options.look == .two {
                    // Fix round 1: the bank's eyes come in pairs, a few at a time, at depths of their own, with or
                    // without the Gloom's fog.
                    for item in bankEyes(edgeX: bankEdgeX, animTime: animTime, reduceMotion: options.reduceMotion,
                                         strength: 1, ambient: ambient, geometry: geometry, screens: eyeScreens) {
                        glow.add(item)
                    }
                    for item in fireflies(hour: hour, animTime: animTime, reduceMotion: options.reduceMotion,
                                          geometry: geometry) {
                        glow.add(item)
                    }
                    // Fix round 2 (the critic: "a warm half disc sits cut off at the screen's left edge"): the world's
                    // end hides every glow inside its whole dark (the lord's lantern when he stands at the end).
                    if let end = bankEndTile(geometry: geometry) {
                        glow.occlude(end, plane: .world)
                    }
                }
            }
        }
        // World rebuild, fix round 2: inside the walls at dusk the wedges show a dusk sky (warm toward the horizon, no
        // stars yet), not the night's.
        let cleftDusk = options.look == .two ? cleftDuskShare(focus: geometry.focusX, ambient: ambient) : 0
        var skyAmbient = ambient
        skyAmbient.starAlpha *= Float(1 - cleftDusk)
        let emissives = skyEmissives(ambient: skyAmbient, hour: hour, geometry: geometry,
                                     cleft: options.look == .two ? cleftShare(focus: geometry.focusX) : 0)
            + glow.items

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
                // World-3 fix round 2 (the critic's high 8): on a hard night a cold ground fog swallows the feet of
                // the mid plane and the lane's, before the Gloom's dark strips (`GloomFog.groundStrip`).
                if gloom.groundShare > 0.01 {
                    let ground = gloomSlices(gloom, strip: GloomFog.groundStrip, edgeX: bankEdgeX, hour: hour,
                                             value: value, clearings: clearings, animTime: animTime,
                                             reduceMotion: options.reduceMotion, geometry: geometry)
                    planeSprites[GloomFog.groundStrip.plane.rawValue] += ground.map {
                        GloomFog.groundTinted($0, share: gloom.groundShare)
                    }
                }
                planeSprites[Plane.fogB.rawValue] += gloomWisps(gloom, edgeX: bankEdgeX, hour: hour, value: value,
                                                                clearings: clearings, animTime: animTime,
                                                                reduceMotion: options.reduceMotion,
                                                                geometry: geometry)
            }
        }

        if options.look == .two {
            // World rebuild: the darkness bank's sheets on both fog planes, in front of the hour's fog and the
            // Gloom's strips (the bank is the darkest thing there, with or without the fog effect). Painted in the
            // night's own colours, so the lift the shader gives a fog plane is taken out of their tint.
            let value = 1 / max(1, Look2.fogBrightness(ambient))
            for sheet in bankSheets where sheet.plane != .world {
                var tint = bankTint(sheet.sprite, ambient: ambient)
                tint.x *= value
                tint.y *= value
                tint.z *= value
                planeSprites[sheet.plane.rawValue] += bankSheetTiles(sheet, edgeX: bankEdgeX, tint: tint,
                                                                     animTime: animTime,
                                                                     reduceMotion: options.reduceMotion,
                                                                     geometry: geometry)
            }
            // Fix round 1: where the world ends the dark is whole (the last 80 px, before everything).
            if let end = bankEndTile(geometry: geometry) {
                planeSprites[Plane.fogB.rawValue].append(end)
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
                         skyTop: ambient.skyTop + (ambient.skyBottom - ambient.skyTop) * (Float(cleftDusk) * cleftDuskWarmth),
                         skyBottom: ambient.skyBottom,
                         starAlpha: skyAmbient.starAlpha,
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
            if let gloom, fogUp > 0 {
                // World-3 fix round 1 (the critic's high 3): a hard night's fog eats the mid plane (`midVeil`).
                desc.gloomHaze = GloomFog.midHaze(gloom, presence: fogUp,
                                                  front: gloom.front(bankEdge: bankEdgeX, hour: hour),
                                                  left: camera.x, width: camera.viewWidth)
            }
        }
        return desc
    }

    // MARK: - Sky

    /// Stars, the moon and the sun on the sky plane (parallax 0: target pixels are screen pixels).
    private static func skyEmissives(ambient: AmbientSample, hour: Double, geometry: Geometry,
                                     cleft: Double = 0) -> [EmissiveInstance] {
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
            // World rebuild, fix round 1: inside the walls the sky is two wedges between the rock, and the moon stands
            // in the one over the bailey (an emitter of the cleft wall, `SceneLayout.look2Rock`); the open sky's
            // moon gives way to it.
            let alpha = min(1, max(0, ambient.moonHeight * 3 + 0.3)) * veil * Float(1 - cleft)
            let moon = GamePalette.moon
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            let color = SIMD4<Float>(moon.x, moon.y, moon.z, alpha)
            if alpha > 0.003 {
                list.append(EmissiveInstance(sprite: .moon, plane: .sky, rect: rect, color: color))
            }
        }

        if ambient.sunHeight > -0.1 {
            let size = SpriteID.sun.size
            let progress = min(1, max(0, (hour - 6) / 13))
            let centre = Double(width) * (0.85 - 0.7 * progress)
            let lift = Int((Double(ambient.sunHeight) * 110).rounded())
            let top = max(2, ground - 40 - lift)
            let left = Int(centre.rounded()) - size.width / 2
            // In the cleft the sun stands behind the wall (its bloom must not shine through the rock).
            let alpha = min(1, max(0, ambient.sunHeight * 5 + 0.5)) * veil * Float(1 - cleft)
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

    // MARK: World rebuild, step world-2 (SceneLayoutCastle.swift)

    /// The castle's chimney smoke (`SceneLayout.castleChimney`) on the plane of its prop, placed by the plane the prop
    /// moves with (the keep's moves with the mist band). Fix round 1 (the critic's high 3): puffs that rise and drift
    /// (`CastleSmoke`), white × a pale value, so the hour's light gives them a value over the rock behind; the
    /// bakehouse's take the warm glow of its chimney's mouth from below. Reduce Motion: they stand still.
    /// b3-wind: build 3 step 5 (lane 3, the director's call 1 of 11:07): the plume leans with the wind at the chimney
    /// (`CastleSmoke.angle`), torn in a storm; under Reduce Motion it stands leaned by the steady wind; the back row's
    /// chimneys smoke dimmer, slow to show and with no fire under them (`CastleSmoke.puffs(back:)`).
    private static func castleSmoke(props: [Prop], plane: Plane, animTime: Double, reduceMotion: Bool,
                                    geometry: Geometry, ambient: AmbientSample,
                                    glow: inout EmissiveList) -> [SpriteInstance] {
        let weather = geometry.weather
        let size = SpriteID.smokePuff.size
        let value = CastleSmoke.value
        var list: [SpriteInstance] = []
        for prop in props where prop.plane == plane {
            guard let chimney = SceneLayout.castleChimney(prop) else { continue }
            let whole = geometry.whole(prop.movesWith ?? prop.plane)
            let wind = reduceMotion ? weather.mean : Weather.wind(at: chimney.x, weather, time: animTime)
            let time = reduceMotion ? 0 : animTime
            let fire = prop.sprite == .bakehouse
            // b3-wind (step 5): the back row's soft puffs.
            let back = SceneLayout.townRowSprites.contains(prop.sprite)
            for puff in CastleSmoke.puffs(time: time, wind: wind, seed: Int(chimney.x), back: back)
                where puff.alpha > 0.02 {
                let left = (chimney.x + puff.dx - Double(size.width) / 2 - whole).rounded()
                guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
                let top = geometry.top(y: (chimney.y + puff.rise).rounded(), height: Double(size.height))
                let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
                list.append(SpriteInstance(sprite: .smokePuff, frame: puff.frame, rect: rect,
                                           tint: SIMD4<Float>(value, value, value * 1.02, puff.alpha), flipped: false))
                // Round lh-w2f1-2: lit only as albedo, the puffs sank into the night's rock. World-3: a light of
                // their own at every hour (`CastleSmoke.glow`: day, dusk sky, moon, the chimney's fire from below).
                let rgb = CastleSmoke.glow(ambient, rise: puff.rise, fire: fire, hearth: !back)
                glow.add(EmissiveInstance(sprite: .smokePuff, plane: plane, rect: rect,
                                          color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, puff.alpha), frame: puff.frame))
            }
        }
        return list
    }

    /// Fix round 1 (the critic's high 10: "the moon moves at about half the camera and sits on the keep's roof line"):
    /// inside the walls the moon stands on the sky, still on the screen (factor 0), `wedgeMoonX` columns from its left
    /// and `wedgeMoonTop` rows under its top (under the HUD). It goes into the emissive pass before the mid plane's
    /// rock, so the cleft wall hides it but where a wedge of sky passes over it (the Throat's wedge, the camera about
    /// 1600), clear of the keep, which stands far to its right there; at dusk it is not up yet.
    /// How strong the keep's warm west rim is (fix round 1): by the hour's warmth (none at noon and at night, full from
    /// the golden hour to sunset, fading through the dusk) and gone once the moon is up.
    static func keepRimShare(_ ambient: AmbientSample) -> Float {
        min(1, max(0, ambient.warmth / 0.25)) * (1 - wedgeMoonShare(ambient))
    }

    static let wedgeMoonX = 106.0
    static let wedgeMoonTop = 34.0
    private static func wedgeMoon(ambient: AmbientSample, geometry: Geometry) -> EmissiveInstance? {
        let share = Float(cleftShare(focus: geometry.focusX)) * ambient.torchStrength * wedgeMoonShare(ambient)
        guard share > 0.01 else { return nil }
        let size = SpriteID.moon.size
        let rect = SIMD4<Float>(Float(wedgeMoonX) - Float(size.width / 2), Float(wedgeMoonTop), Float(size.width),
                                Float(size.height))
        let moon = GamePalette.moon * share
        return EmissiveInstance(sprite: .moon, plane: .mid, rect: rect, color: SIMD4<Float>(moon.x, moon.y, moon.z, 1))
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
        var prop = prop
        if options.look == .two,
           let pose = WindLook.pose(of: prop, weather: geometry.weather, time: animTime,
                                    reduceMotion: options.reduceMotion) {
            // Build 3, POLISH pass 1 (lane 3): the windmill's sails and the flags take their frame from the wind.
            prop.frame = pose.frame
            prop.flipped = pose.flipped
            prop.x += pose.dx
        }
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
        if options.look == .two && (prop.plane == .far || prop.plane == .clouds) {
            // World rebuild (B5, H1): inside the walls the cleft wall fills the view up to its slit of sky, and the
            // far plane is gone (it fades while the gatehouse and the steps cover it, and comes back at the back gate).
            // Fix round 1 (the director: "the slit at dusk reads as autumn leaves"): the high clouds go with it, so
            // the wedges of sky show the sky's own gradient, the stars and the moon.
            alpha *= Float(1 - cleftShare(focus: geometry.focusX))
        }
        guard alpha > 0.003 else { return }
        let bottom = geometry.bottom(of: prop)
        let top = geometry.top(y: bottom, height: height)
        let rect = SIMD4<Float>(Float(left), Float(top), Float(prop.width), Float(prop.height))
        var tint = SIMD4<Float>(prop.shade, prop.shade, prop.shade, alpha * prop.alpha)
        if options.look == .two && prop.plane == .mid && SceneLayout.look2CleftPieces.contains(prop.sprite) {
            // World-2 (the critic of world-1, look 3: "the wall at night is a pale moonlit cardboard face, brighter than
            // the castle"): the cleft's granite a step darker as the night comes, so the castle's windows carry it.
            let dim = 1 - SceneLayout.look2CleftNightDim * Look.nightness(ambient)
            tint.x *= dim
            tint.y *= dim
            tint.z *= dim
        }
        if options.look == .two && prop.sprite == .posternNightView {
            // World-3 fix round 2 (the critic's high 4): the postern's far view at night, by the night's moon.
            tint.w *= SceneLayout.posternNightShare(ambient)
            guard tint.w > 0.003 else { return }
        }
        if options.look == .two && prop.plane == .world && SceneLayout.beaconStages.contains(prop.sprite) {
            // World-3 fix round 3 (the critic's blocker 1 of look 3): the beacon takes the night like the cliff.
            let night = SceneLayout.beaconNightTint(ambient)
            tint.x *= night.x
            tint.y *= night.y
            tint.z *= night.z
        }
        if options.look == .two && SceneLayout.townRowSprites.contains(prop.sprite) {
            // World-3 (M4): the town's back row a step darker as the night comes (the near plane's night haze lifted
            // its pale plaster over the front houses').
            let dim = 1 - SceneLayout.look2TownRowNightDim * Look.nightness(ambient)
            tint.x *= dim
            tint.y *= dim
            tint.z *= dim
        }
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
            if options.look == .two && (prop.plane == .fogA || prop.plane == .fogB) {
                // World-2 fix round 1: a bank of mist on a fog plane (the keep's) takes the hour's fog colour, as the
                // fog's own tiles do; the shader lifts it like the fog. Fix round 2 (the critic's high 1): at night a
                // dim, desaturated night grey, one value step over the keep's foot (`SceneLayout.castleMistTint`).
                tint = SceneLayout.castleMistTint(ambient, strength: strength)
            }
            hidesGlow = false
        } else if let share = prop.sunShaft {
            // World rebuild: a shaft of light is white at the sun's strength (none at night, less under cloud).
            let strength = sunShaftAlpha(share, ambient: ambient) * alpha * prop.alpha
                * Float(1 - geometry.weather.cover)
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
                glow.add(bentFlame(emissive, part: part, prop: prop, animTime: animTime, options: options,
                                   geometry: geometry))
            }
        }
        let torch = ambient.torchStrength
        guard torch > 0.01 else { return }
        // World-2: the keep's windows (it moves with the mist band, farther off than the world plane) a step dimmer.
        let haze: Float = prop.plane == .mid && prop.region == .gorge ? gorgeMidGlass
            : prop.movesWith == .mistBand ? keepGlass : 1
        // World-2 fix round 2 (the director's note of 07:47, item 6): the castle's lit glass halfway to the torch's
        // amber, the chapel's lancets no brighter than the keep's windows (`SceneLayout.castleAmberGlass`).
        let amber = options.look == .two && SceneLayout.castleAmberGlass.contains(prop.sprite)
        let castleTint = amber ? SceneLayout.castleAmberTint * SceneLayout.castleGlassShare(prop.sprite)
                               : SIMD3<Float>(repeating: 1)
        for mask in prop.masks {
            let gain = options.look == .two ? glassGain * look2GlassGain : glassGain
            // World-3 fix round 2 (the critic's high 5): the far lantern's glass in the gate torches' colour.
            let glassColor = options.look == .two ? (SceneLayout.look2GlassColor(prop.sprite) ?? mask.color) : mask.color
            let rgb = glassColor * castleTint * (torch * gain * haze)
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
        if SceneLayout.castleKeepRims.contains(part.sprite) || part.sprite == .keepFlagRim
            || part.sprite == .castleBannerRim {
            // World-2 fix round 1 (blocker 1): the keep's warm west rim while the evening sun is low and warm (build 3
            // step 2, lane 3: on the flags' cloth too).
            strength *= keepRimShare(ambient)
        }
        if SceneLayout.beaconRims.contains(part.sprite) || SceneLayout.look2MoonRims.contains(part.sprite) {
            // World-3 (M2): the beacon's moon rim rises with the night's moon, not with the torches.
            strength *= wedgeMoonShare(ambient)
        }
        if part.sprite == .moon && options.look == .two {
            // World rebuild, fix round 2: the moon in the cleft's wedge rises with the night's moon, not with the
            // torches (the critic: "dusk looks the same as night: the same full moon in the same place").
            strength *= wedgeMoonShare(ambient)
        }
        if options.look == .two && (part.sprite == .flame || part.sprite == .brazierFlame) && !enclosed(prop) {
            // Build 3, POLISH pass 1 (lane 3): a torch's or a brazier's flame gutters with its light in the wind.
            let lean = Weather.fireLean(x: prop.x + part.dx, geometry.weather, time: animTime,
                                        reduceMotion: options.reduceMotion)
            strength *= Float(1 - Weather.fireGutter * abs(lean))
        }
        if let seed = part.flickerSeed {
            let flicker = Flicker.sample(seed: seed, time: animTime * part.flickerPace,
                                         reduceMotion: options.reduceMotion)
            // A fire's own flicker untouched (look 1's golden frames), a share of it for a lit room.
            let swing = Float(flicker.intensity)
            strength *= part.flickerAmount == 1 ? swing : 1 + (swing - 1) * part.flickerAmount
        }
        guard strength > 0.01 else { return nil }
        // Touch the world, fix round 1 (stage lane): a rim, the prop's sprite and frame grown by a pixel left, right
        // and up.
        if part.rim {
            let top = geometry.top(y: bottom, height: Double(prop.height))
            let rgb = part.color * strength
            return EmissiveInstance(sprite: prop.sprite, plane: prop.plane,
                                    rect: SIMD4<Float>(Float(left) - 1, Float(top) - 1, Float(prop.width) + 2,
                                                       Float(prop.height) + 1),
                                    color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1), kind: .rim, flipped: prop.flipped,
                                    frame: prop.frame)
        }
        let dx = prop.flipped ? Double(prop.width) - part.dx - Double(size.width) : part.dx
        let x = left + dx
        let top = geometry.top(y: bottom + part.dy, height: Double(size.height))
        let rect = SIMD4<Float>(Float(x), Float(top), Float(size.width), Float(size.height))
        var rgb = part.color * strength
        if part.sprite == .posternFarGlow && options.look == .two {
            // World-3 fix round 1 (the critic's high 2): the valley through the postern takes the valley's hour.
            rgb = SceneLayout.posternFarColor(ambient) * strength
        }
        let color = SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)
        if part.sprite == .castleBannerRim {
            // Build 3 step 3 (lane 3, the critic's M4): the banner's rim follows its pose (it is never mirrored).
            return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color, frame: prop.frame)
        }
        if part.sprite == .keepFlagRim {
            // Build 3 step 2 (lane 3): the flag's rim follows its frame; a flag mirrored to stream west takes the rim
            // drawn on its other edges (frames from `Weather.flagFrames`), so mirrored it still faces the low sun.
            return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color,
                                    flipped: prop.flipped,
                                    frame: prop.frame + (prop.flipped ? Weather.flagFrames : 0))
        }
        return EmissiveInstance(sprite: part.sprite, plane: prop.plane, rect: rect, color: color,
                                flipped: part.mirrors && prop.flipped)
    }

    /// Build 3 step 2 (lane 3, the critic's M1): the props whose fire burns behind a wall, out of the wind: the forge
    /// in the smithy (its flame neither gutters nor bends; `EntityFrames.smithyLeft`).
    static let enclosedFires: Set<SpriteID> = [.smithy, .masterSmithy]

    private static func enclosed(_ prop: Prop) -> Bool {
        enclosedFires.contains(prop.sprite)
    }

    /// A light that burns out of the wind: the bakehouse's oven through its hatch (`SceneLayout.castleBakeHatchLight`)
    /// and the forge (`EntityFrames` lights it at the smithy's hearth); their pools neither lean nor gutter.
    static func windproof(_ source: LightSource) -> Bool {
        let hatch = SceneLayout.castleBakeHatchLight
        if source.kind == .torch && source.x == SceneLayout.castleBakehouseX + hatch.dx && source.y == hatch.y {
            return true
        }
        let forge = [EntityFrames.smithyLeft + 19, EntityFrames.smithyLeft + 21]
        return source.kind == .brazier && source.y == 16 && source.radius == 26 && forge.contains(source.x)
    }

    /// The rows of an open flame that lean with the wind, from its top down, by how far. Step 3 (the critic's M3, the
    /// director: "the bent flame bends whole"): every row is sheared by its height over the foot, so the outline stays
    /// joined and no tip ever stands loose above the body: the top row `reach` pixels downwind (3 at a whole lean, 2 or
    /// 1.5 at a lean from `flameBendFrom`), the rows under it less (by the height to the 1.3), the foot where it burns.
    /// A torch's flame of 5 rows at a whole lean: 3, 2, 1; a brazier's of 7: 3, 2, 2, 1, 1. None in a calm, none with
    /// Reduce Motion beyond the steady wind's.
    static func flameBend(lean: Double, rows: Int) -> [(rows: Int, shift: Int)] {
        let force = abs(lean)
        guard force >= flameBendFrom, rows > 1 else { return [] }
        let sign = lean < 0 ? -1 : 1
        let reach = force >= 0.75 ? 3.0 : (rows >= 7 ? 2.0 : 1.5)
        var bands: [(rows: Int, shift: Int)] = []
        for row in 0..<rows {
            let height = Double(rows - 1 - row) / Double(rows - 1)
            let shift = Int((reach * pow(height, 1.3)).rounded()) * sign
            if shift == 0 { break }
            if let last = bands.last, last.shift == shift {
                bands[bands.count - 1].rows += 1
            } else {
                bands.append((rows: 1, shift: shift))
            }
        }
        return bands
    }

    /// The lean from which an open flame bends (step 3, the critic's M3: from a quarter, so a gusty day shows it).
    static let flameBendFrom = 0.25

    /// The frame of `flameBent` / `brazierFlameBent` for a lean as the flame is drawn (its own mirroring undone): 0 and
    /// 1 bend toward the valley (a third, a whole lean), 2 and 3 toward the west; nil while it stands
    /// (`PlaceholderWeather.bentFlameLeans` paints them by `flameBend`).
    static func bentFlameFrame(lean: Double, flipped: Bool) -> Int? {
        let drawn = flipped ? -lean : lean
        let force = abs(drawn)
        guard force >= flameBendFrom else { return nil }
        return (force >= 0.75 ? 1 : 0) + (drawn < 0 ? 2 : 0)
    }

    /// The bent sprite of an open flame, nil for every other emissive.
    static func bentSprite(of sprite: SpriteID) -> SpriteID? {
        switch sprite {
        case .flame: return .flameBent
        case .brazierFlame: return .brazierFlameBent
        default: return nil
        }
    }

    /// Build 3 step 2 (lane 3, the critic's M1: at phone size the lean of the light alone was not seen): a torch's or a
    /// brazier's flame bends with the wind, drawn as the bent sprite's frame for its lean (`flameBend`'s top rows
    /// downwind, the foot where it burns; one quad, two pixels wider on each side). The forge's does not
    /// (`enclosedFires`).
    private static func bentFlame(_ flame: EmissiveInstance, part: EmissivePart, prop: Prop, animTime: Double,
                                  options: FrameOptions, geometry: Geometry) -> EmissiveInstance {
        guard options.look == .two, geometry.weather != .clear, let sprite = bentSprite(of: part.sprite),
              !enclosed(prop) else { return flame }
        let lean = Weather.fireLean(x: prop.x + part.dx, geometry.weather, time: animTime,
                                    reduceMotion: options.reduceMotion)
        guard let frame = bentFlameFrame(lean: lean, flipped: flame.flipped) else { return flame }
        let grow = Float(sprite.size.width - part.sprite.size.width) / 2
        return EmissiveInstance(sprite: sprite, plane: flame.plane,
                                rect: SIMD4<Float>(flame.rect.x - grow, flame.rect.y, flame.rect.z + 2 * grow,
                                                   flame.rect.w),
                                color: flame.color, flipped: flame.flipped, frame: frame)
    }

    /// World-3 fix round 1 (the critic's high 8): the far shore's lantern (near plane) laid on the water as a broken
    /// streak under it, from the water's far edge (y −6) down; its rect in the near plane's pixels, drawn after the
    /// world plane so the water does not hide it. Nil while the lantern is out of view or dark.
    private static func riverLanternStreak(props: [Prop], ambient: AmbientSample,
                                           geometry: Geometry) -> EmissiveInstance? {
        guard let lantern = props.first(where: { $0.sprite == .riverFarLantern && $0.plane == .near }) else {
            return nil
        }
        let strength = ambient.torchStrength * SceneLayout.look2RiverStreakGain
        guard strength > 0.01 else { return nil }
        let size = SpriteID.riverLanternStreak.size
        let left = lantern.x - geometry.whole(.near) + 6   // world-3 fix round 2: the 7 px streak under the glass
        guard geometry.isVisible(left: left, width: Double(size.width)) else { return nil }
        let top = geometry.top(y: -6 - Double(size.height - 1), height: Double(size.height))
        let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
        let rgb = SIMD3<Float>(1.0, 0.6, 0.26) * strength   // the fire's amber, darker on the water
        return EmissiveInstance(sprite: .riverLanternStreak, plane: .near, rect: rect,
                                color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1))
    }

    // MARK: - World rebuild, step world-1 (DESIGN.md "World rebuild (14.11.2026)")

    /// The hour's fog tiles overlap by this much (look 2, tools/fogart.py `OVERLAP`).
    static let fogOverlap = 64

    /// One sheet of the darkness bank (tools/fogart.py): its plane, its painting, how far past the bank's edge its
    /// leading face reaches (the low front sheet creeps ahead, the tall back one leans behind), and its breath.
    struct BankSheet: Sendable, Equatable {
        var plane: Plane
        var sprite: SpriteID
        var face: Double
        var sway: Double
        var period: Double
        var phase: Double
    }

    /// The darkness bank (REVIEW-look-2.md 2.5, B4): three sheets of feathered fog at the lane's own parallax (like
    /// the Gloom's strips), so they move with the bank's edge as one soft volume. On fog A behind the creatures the
    /// tall, thin sheet whose billowing crest stands near the screen's top, on the lane's plane after its props the
    /// darker sheet whose crest lies at about half the screen (it hides what stands low in the bank), on fog B before
    /// everything the darkest, low roll; their faces breathe against each other. Fix round 1: each a face and body
    /// tiles that hold every pixel once (`bankSheetTiles`), tinted by the hour (`bankTint`).
    static let bankSheets = [
        BankSheet(plane: .fogA, sprite: .bankSheetA, face: 24, sway: 3, period: 11, phase: 0),
        BankSheet(plane: .world, sprite: .bankSheetB, face: 8, sway: 4, period: 8, phase: 0.4),
        BankSheet(plane: .fogB, sprite: .bankSheetC, face: 44, sway: 7, period: 6, phase: 0.75),
    ]
    /// The sheets' bottom: four rows under the lowest screen row.
    static let bankSheetY = -Double(WorldLayout.groundRowsBelow) - 4

    /// The world x of a sheet's leading face (its right end): the bank's edge plus its reach, breathing (never with
    /// Reduce Motion), in whole pixels.
    static func bankFace(_ sheet: BankSheet, edgeX: Double, animTime: Double, reduceMotion: Bool) -> Double {
        let breath = reduceMotion ? 0 : sheet.sway * sin(2 * Double.pi * (animTime / sheet.period + sheet.phase))
        return (edgeX + sheet.face + breath).rounded()
    }

    /// One plane's sheets across the screen (fix round 1): the leading face (frame 1) with its right end at the face,
    /// then body tiles (frame 0) every `width − fogOverlap` px westward to the screen's left end, returned west
    /// first.
    /// Neighbours overlap by `fogOverlap` px with complementary dithered feathers, so each pixel is held by exactly
    /// one tile and a translucent sheet stays one even veil. `tint` is the hour's (`bankTint`).
    private static func bankSheetTiles(_ sheet: BankSheet, edgeX: Double, tint: SIMD4<Float>, animTime: Double,
                                       reduceMotion: Bool, geometry: Geometry) -> [SpriteInstance] {
        let size = sheet.sprite.size
        let width = Double(size.width)
        let period = width - Double(fogOverlap)
        let world = geometry.whole(.world)
        let face = bankFace(sheet, edgeX: edgeX, animTime: animTime, reduceMotion: reduceMotion)
        let top = geometry.top(y: bankSheetY, height: Double(size.height))
        var list: [SpriteInstance] = []
        var left = face - width - world
        var frame = 1
        while left + width >= -1 {
            if geometry.isVisible(left: left, width: width) {
                let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
                list.append(SpriteInstance(sprite: sheet.sprite, frame: frame, rect: rect, tint: tint, flipped: false))
            }
            left -= period
            frame = 0
        }
        return list.reversed()
    }

    /// The bank's eyes as glow on the world plane (fix round 1, `bankEyePairs`): drawn after the sheet on the lane, so
    /// no fog of its own hides them; the low roll on fog B veils the lowest.
    private static func bankEyes(edgeX: Double, animTime: Double, reduceMotion: Bool, strength: Float,
                                 ambient: AmbientSample, geometry: Geometry,
                                 screens: [ClosedRange<Double>] = []) -> [EmissiveInstance] {
        let size = SpriteID.darknessBankGlow.size
        let whole = geometry.whole(.world)
        var list: [EmissiveInstance] = []
        var taken: [Double] = []
        for eye in bankEyePairs(edgeX: edgeX, time: animTime, reduceMotion: reduceMotion) {
            guard let x = EyeRules.placed(x: eye.x, width: Double(size.width), y: eye.y, screens: screens) else {
                continue
            }
            // World-3 fix round 3: two pairs moved off the same building would stand on one spot
            guard !taken.contains(where: { abs($0 - x) < 40 }) else { continue }
            taken.append(x)
            let left = x - whole
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
            let value = bankEyeStrength(eye, ambient: ambient) * strength
            guard value > 0.02 else { continue }
            let top = geometry.top(y: eye.y, height: Double(size.height))
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(EmissiveInstance(sprite: .darknessBankGlow, plane: .world, rect: rect,
                                         color: SIMD4<Float>(value, value, value, 1), frame: eye.frame))
        }
        return list
    }

    /// Where the world ends (x 0) the dark is whole: `bankEnd` on fog B, drawn black (fix round 1).
    private static func bankEndTile(geometry: Geometry) -> SpriteInstance? {
        let size = SpriteID.bankEnd.size
        let left = -geometry.whole(.world)
        guard geometry.isVisible(left: left, width: Double(size.width)) else { return nil }
        let top = geometry.top(y: bankSheetY, height: Double(size.height))
        let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
        return SpriteInstance(sprite: .bankEnd, frame: 0, rect: rect, tint: SIMD4<Float>(0, 0, 0, 1), flipped: false)
    }

    /// The cleft's threads of water (fix round 2; tools/cleftart.py `THREADS`): each thread's notch (mid x) and its row
    /// under the wall's top (the wall is anchored at the screen's top, so the row is the screen's). Two, far apart, each
    /// with a shape of its own in `cleftWater` (frames 0-5 and 6-11): it falls in an S over two short ledges and ends in
    /// spray on a third, over the castle's roofs.
    static let cleftThreads: [(x: Double, row: Double)] = [(893, 26), (1258, 30)]
    /// The columns of room west of a thread's notch in its `cleftWater` frame, and the frames per thread.
    static let cleftWaterInset = 5.0
    static let cleftWaterFrames = 6
    /// World-2 fix round 2 (the director's note of 07:47, item 7): the threads a little thinner, so the one that passes
    /// behind the keep's stair turret no longer reads as a pole on it.
    static let cleftWaterAlpha: Float = 0.6

    /// The water falling down the cleft wall from each notch to its last spray: its own frames of `cleftWater`
    /// scrolling down at six a second, still with Reduce Motion.
    private static func cleftWater(animTime: Double, reduceMotion: Bool, geometry: Geometry) -> [SpriteInstance] {
        let size = SpriteID.cleftWater.size
        let step = reduceMotion ? 0 : Int((max(0, animTime) * 6).rounded(.down)) % cleftWaterFrames
        let whole = geometry.whole(.mid)
        var list: [SpriteInstance] = []
        for (index, thread) in cleftThreads.enumerated() {
            let left = thread.x - cleftWaterInset - whole
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
            let rect = SIMD4<Float>(Float(left), Float(thread.row + 1), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .cleftWater, frame: index * cleftWaterFrames + step, rect: rect,
                                       tint: SIMD4<Float>(1, 1, 1, cleftWaterAlpha), flipped: false))
        }
        return list
    }

    /// How deep the camera stands in the cleft (0 outside ... 1 between the gatehouse and the back gate): the open
    /// sky's moon gives way to the one in the wedge of sky and the sun stands behind the rock.
    static func cleftShare(focus: Double) -> Double {
        let enter = AmbientRamp.smoothstep((focus - 1240) / 140)
        let leave = AmbientRamp.smoothstep((focus - 2300) / 160)
        return enter * (1 - leave)
    }

    /// How far the wedge moon is up (fix round 2): none while the night's moon is low (dusk), all of it from the blue
    /// hour on.
    static func wedgeMoonShare(_ ambient: AmbientSample) -> Float {
        Float(AmbientRamp.smoothstep(Double((ambient.moonHeight - 0.25) / 0.25)))
    }

    /// How much of the cleft's sky is dusk's (fix round 2): deep in the cleft while the torches burn and the moon is not
    /// up yet; 0 by day, at night and outside the walls.
    static func cleftDuskShare(focus: Double, ambient: AmbientSample) -> Double {
        let torch = AmbientRamp.smoothstep(Double(ambient.torchStrength) / 0.6)
        return cleftShare(focus: focus) * torch * (1 - Double(wedgeMoonShare(ambient)))
    }
    /// How far the sky's top takes the horizon's colour in the cleft at dusk.
    static let cleftDuskWarmth: Float = 0.38

    /// The alpha of a shaft of light: the sun's strength (as the cast shadows', `sunShadowAlpha`) times its share.
    static func sunShaftAlpha(_ share: Float, ambient: AmbientSample) -> Float {
        share * min(1, max(0, (ambient.sunHeight + 0.12) / 0.3))
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
        // World rebuild (M1): look 2's fog stands still under Reduce Motion; look 1 drifts slowly as it did.
        let slow = reduceMotion ? (look == .two ? 0 : Flicker.reducedRateScale) : 1.0
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
        // World rebuild (B4): each tile feathers out at both ends and the next one lies `fogOverlap` px over it,
        // their feathers dithered against each other, so the bank goes on unbroken (tools/fogart.py).
        let stride = Double(size.width - fogOverlap)
        let whole = geometry.whole(layer.plane)
        let drift = Double(layer.drift).rounded(.down).truncatingRemainder(dividingBy: stride)
        let top = geometry.top(y: baseY, height: Double(size.height))
        let tint = SIMD4<Float>(layer.color.x, layer.color.y, layer.color.z, min(1, layer.density))
        let first = Int(((whole + drift) / stride).rounded(.down)) - 1
        let count = Int(Double(geometry.targetWidth) / stride) + 3
        var list: [SpriteInstance] = []
        for index in first..<(first + count) {
            let left = Double(index) * stride - drift - whole
            guard geometry.isVisible(left: left, width: Double(size.width)) else { continue }
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

    /// World rebuild (B4): how many parts a slice is cut into where the fire's hole changes the cover by `step`
    /// across it: whole below 0.06, halves below 0.18, quarters above.
    static func gloomSubSlices(_ step: Double) -> Int {
        step > 0.18 ? 4 : step > 0.06 ? 2 : 1
    }
    /// The eyes glow a little over white, so the bloom catches them at phone size.
    static let gloomEyeGain: Float = 1.4

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
                    // World rebuild (B4): where a fire's hole changes the cover steeply across a slice, the slice is
                    // cut finer (8 or 4 px), so the fog thins toward the fire in small steps, never in 16 px columns.
                    let ends = abs(GloomFog.hole(x: left + world, clearings: clearings)
                                   - GloomFog.hole(x: left + slice + world, clearings: clearings)) * whole
                    let parts = gloomSubSlices(ends)
                    let width = gloomSlice / parts
                    for part in 0..<parts {
                        let partLeft = left + Double(part * width)
                        let x = partLeft + Double(width) / 2 + world
                        let cover = whole * (1 - GloomFog.hole(x: x, clearings: clearings))
                        guard cover > 0.012 else { continue }
                        let rect = SIMD4<Float>(Float(partLeft), Float(top), Float(width), Float(size.height))
                        let source = SIMD4<Float>(Float(k * gloomSlice + part * width), 0, Float(width),
                                                  Float(size.height))
                        list.append(SpriteInstance(sprite: strip.sprite, frame: face ? 1 : 0, rect: rect,
                                                   tint: SIMD4<Float>(value, value, value, Float(min(1, cover))),
                                                   flipped: false, source: source))
                    }
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

    /// The cold eyes that open and close in the fog as glow on the world plane, dimmed where a fire clears it.
    private static func gloomEyes(_ gloom: GloomFog, edgeX: Double, hour: Double, clearings: [GloomFog.Clearing],
                                  animTime: Double, reduceMotion: Bool, geometry: Geometry,
                                  screens: [ClosedRange<Double>] = []) -> [EmissiveInstance] {
        let size = SpriteID.eyeGlints.size
        let whole = geometry.whole(.world)
        var list: [EmissiveInstance] = []
        for eyes in gloom.eyes(bankEdge: edgeX, hour: hour, time: animTime, reduceMotion: reduceMotion) {
            // (They stand behind everything on the lane: the buildings drawn after them hide them. The ceiling only.)
            // World-3 fix round 3 (the critic's high 3): never within `EyeRules.clearance` of a building either.
            guard let x = EyeRules.placedInFog(x: eyes.x, width: Double(size.width), y: eyes.y,
                                               screens: screens) else {
                continue
            }
            let left = x - whole
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
        rainSlant(force: abs(weather.mean))
    }
    /// The slant for a wind's force (build 3 step 2: each streak reads the wind where it falls, so a gust leans it
    /// further as the gust passes; in a calm it falls straight).
    static func rainSlant(force: Double) -> Int {
        force < 0.2 ? 0 : (force < 0.6 ? 1 : 2)
    }
    /// How many of `full` fall in a rain of this strength: by its root, so a light rain (0.4) is still rain on a
    /// phone (round lh-l2-3a: at 0.6 a count in proportion read as a few stray streaks).
    static func rainCount(_ full: Int, rain: Double) -> Int {
        Int((Double(full) * max(0, min(1, rain)).squareRoot()).rounded())
    }
    /// Polish after round 2, the rain over a bright scene: a streak in the scene's own tone is lost. Build 3 step 3 (the
    /// critic's H2 (d), the director's call 1): by day the water is the light thing that falls, a cool pale grey lighter
    /// than the sky behind it (the way rain reads in pixel art; the ash is the one dark thing that falls), a little
    /// denser; pale as painted from dusk on, where the fires light it. The tint goes over 1 so the drawn streak comes
    /// out about 0.8 under a rainy noon's light, over the sky's 0.5 (the plane's texel times the tint times the alpha
    /// stays under 1, the plane's store).
    static let rainDayShade = SIMD3<Float>(1.30, 1.36, 1.50)
    static let rainDayAlpha: Float = 1.08
    /// By day the foreground's plane takes a little over half the lane's ambient (`Look2.fgAmbient`): its streaks are
    /// tinted up by this to read as pale as the lane's. The far layer (the near plane's) falls fainter by day.
    static let rainForegroundLift: Float = 1.5
    static let rainFarDayAlpha: Float = 0.7
    /// Step 4 (the wind critic's M1): by day the lane's streaks wholly in the sky band, above the treeline (more than
    /// `rainSkyRows` over the ground line), fall at `rainSkyDayAlpha`: the 0.49 cap keeps a streak from being a ledge on
    /// the ground, and the sky needs none (at 0.43 the water over the band's sky drew 29 of 255 over it, a faint line).
    static let rainSkyDayAlpha: Float = 0.65
    static let rainSkyRows = 50.0
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
    /// A depth's streak tint (step 3): `rainTint`, by day the foreground's lifted and the far layer's fainter.
    static func rainStreakTint(depth: Int, ambient: AmbientSample) -> SIMD4<Float> {
        let shade = rainShade(ambient)
        var tint = rainTint(alpha: rainDepths[depth].alpha, ambient: ambient)
        if depth == 2 {
            let lift = 1 + (rainForegroundLift - 1) * shade
            tint.x *= lift
            tint.y *= lift
            tint.z *= lift
        } else if depth == 0 {
            tint.w *= 1 + (rainFarDayAlpha - 1) * shade
        }
        return tint
    }
    /// Step 3 (the critic's H1, the director's call 2): at night a streak of the lane's or the foreground's depth near a
    /// light gets a faint cool emissive copy, so the rain is seen at night where light falls on it: this grey at the
    /// light's foot, fading to nothing at `rainLiftReach` of its radius, from a torch strength of 0.5 to full at 0.8;
    /// at most `rainLiftCap` copies a depth.
    static let rainNightLift = SIMD3<Float>(0.22, 0.24, 0.28)
    static let rainLiftReach = 1.6
    static let rainLiftCap = 40
    /// Step 3 (the director's call 5): with Reduce Motion neither rain hangs frozen in the air. A third of the streaks,
    /// flakes and splashes stand where they are and each fades in and out in place over `rainPulse` seconds, at a moment
    /// of its own; nothing travels.
    static let rainPulse = 2.0
    static func rainPulseAlpha(time: Double, own: Double) -> Float {
        Float(0.5 - 0.5 * cos(2 * Double.pi * (time / rainPulse + own)))
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
    /// when the camera moves. Build 3 step 2 (the two rains): a streak falls only where the rain is water at the lane's
    /// x it starts over (`RainLook`: east of the outermost standing wall, thinning out over the band west of it), and
    /// it leans by the wind there at the moment it set off, so a gust leans the streaks it meets further. Step 3: pale
    /// by day (`rainStreakTint`); at night the lane's and the foreground's streaks near a light get a faint cool copy in
    /// the emissive pass (`rainLightSpots`); with Reduce Motion a third of them stand and fade in place.
    private static func rainStreaks(depth: Int, animTime: Double, reduceMotion: Bool, ambient: AmbientSample,
                                    seam: Double, lights: [(x: Double, reach: Double, share: Float)],
                                    geometry: Geometry, glow: inout EmissiveList) -> [SpriteInstance] {
        let weather = geometry.weather
        let entry = rainDepths[depth]
        let count = rainCount(entry.count, rain: weather.rain)
        guard count > 0 else { return [] }
        let fallTime = reduceMotion ? 0 : animTime
        let size = SpriteID.rainStreak.size
        // The furthest any streak leans today (the steady wind and its whole gust), so a streak that leans in a gust
        // still covers the screen's leeward edge.
        let widest = rainSlopes[rainSlant(force: abs(weather.mean) + abs(weather.gust))] * (weather.mean < 0 ? -1 : 1)
        let lowest: Double
        switch entry.plane {
        case .foreground: lowest = Double(geometry.targetHeight)
        case .world: lowest = Double(geometry.groundRow + 3)
        default: lowest = Double(geometry.groundRow - 8)
        }
        let fall = lowest + Double(size.height)
        let reach = abs(widest) * fall
        let span = Double(geometry.targetWidth) + reach
        let whole = geometry.whole(entry.plane)
        let lane = geometry.whole(.world)
        let tint = rainStreakTint(depth: depth, ambient: ambient)
        // Step 4 (M1): the lane's streaks in the sky band a step denser by day.
        let skyAlpha = depth == 1 ? tint.w + (max(tint.w, rainSkyDayAlpha) - tint.w) * rainShade(ambient) : tint.w
        let treeline = Double(geometry.groundRow) - rainSkyRows
        let key = SeededRandom.hash(weather.gustSeed, Int64(depth + 1))
        var lifted = 0
        var list: [SpriteInstance] = []
        for index in 0..<count {
            if reduceMotion && index % 3 != 0 { continue }
            let own = unit(SeededRandom.hash(key, Int64(index)))
            let progress = fallTime * entry.speed / fall + own
            let cycle = progress.rounded(.down)
            let y = (progress - cycle) * fall - Double(size.height)
            let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
            let pick = SeededRandom.hash(SeededRandom.hash(key, turn), Int64(index))
            let column = unit(pick) * span
            var x = (column - whole).truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            x -= widest > 0 ? reach : 0
            // Decided once for the whole fall, at the column it starts from: water or ash (so no streak blinks out in
            // the band), and its lean by the wind of the moment it set off (a gust leans the streaks that start in it,
            // never one in mid-fall).
            let start = x + lane
            guard RainLook.isWater(unit(SeededRandom.hash(pick, 0x57)), x: start, seam: seam) else { continue }
            let born = (cycle - own) * fall / entry.speed
            let wind = Weather.wind(at: start, weather, time: born)
            let leaning = rainSlant(force: abs(wind))
            let lean = rainSlopes[leaning] * (wind < 0 ? -1 : 1)
            x += lean * y
            let rect = SIMD4<Float>(Float(x.rounded(.down)), Float(y.rounded(.down)), Float(size.width),
                                    Float(size.height))
            var alpha = y + Double(size.height) < treeline ? skyAlpha : tint.w
            if reduceMotion {
                alpha *= rainPulseAlpha(time: animTime, own: own)
            }
            list.append(SpriteInstance(sprite: .rainStreak, frame: depth * 3 + leaning, rect: rect,
                                       tint: SIMD4<Float>(tint.x, tint.y, tint.z, alpha), flipped: lean < 0))
            guard depth > 0, !lights.isEmpty, lifted < rainLiftCap else { continue }
            let middle = Double(rect.x) + Double(size.width) / 2
            var near: Float = 0
            for light in lights {
                let closeness = 1 - abs(middle - light.x) / light.reach
                if closeness > 0 {
                    near = max(near, Float(closeness) * light.share)
                }
            }
            guard near > 0.05 else { continue }
            let pulse: Float = reduceMotion ? rainPulseAlpha(time: animTime, own: own) : 1
            let cool = rainNightLift * (near * pulse)
            glow.add(EmissiveInstance(sprite: .rainStreak, plane: entry.plane, rect: rect,
                                      color: SIMD4<Float>(cool.x, cool.y, cool.z, 1), flipped: lean < 0,
                                      frame: depth * 3 + leaning))
            lifted += 1
        }
        return list
    }

    /// Step 3: where the rain catches a light at night: each burning light of the lane's plane (not the moon), as its
    /// screen column, how far its lift reaches (`rainLiftReach` of its radius) and how strong it is at the hour (none
    /// under a torch strength of 0.5, all from 0.8). Empty by day.
    private static func rainLightSpots(sources: [(source: LightSource, plane: Plane)], ambient: AmbientSample,
                                       geometry: Geometry) -> [(x: Double, reach: Double, share: Float)] {
        let share = Float(AmbientRamp.smoothstep(Double((ambient.torchStrength - 0.5) / 0.3)))
        guard share > 0.01 else { return [] }
        let lane = geometry.whole(.world)
        var spots: [(x: Double, reach: Double, share: Float)] = []
        for item in sources where item.plane == .world && item.source.kind != .moon && item.source.radius > 0 {
            let x = item.source.x - lane
            let reach = item.source.radius * rainLiftReach
            guard x + reach >= 0, x - reach <= Double(geometry.targetWidth) else { continue }
            spots.append((x: x, reach: reach, share: share))
        }
        return spots
    }

    /// The splashes where the rain meets the lane: three frames each, then the next one somewhere else. Build 3 step 2:
    /// only where the rain is water (ash never splashes), and on the roofs' ridges too (`rainRidges`): a splash or
    /// two on each roof in view, at places of their own along its ridge. Step 3 (the critic's M5): in a heavy rain the
    /// crown's two pale pixels fly up and out at `rainHeavySplashAlpha`, so the splash shows at phone size; with Reduce
    /// Motion a third of them stand and fade in place.
    private static func rainSplashes(animTime: Double, reduceMotion: Bool, ambient: AmbientSample, seam: Double,
                                     props: [Prop], geometry: Geometry) -> [SpriteInstance] {
        let weather = geometry.weather
        let count = rainCount(rainSplashCount, rain: weather.rain)
        guard count > 0 else { return [] }
        let fallTime = reduceMotion ? 0 : animTime
        let size = SpriteID.rainSplash.size
        let width = Double(geometry.targetWidth)
        let whole = geometry.whole(.world)
        let key = SeededRandom.hash(weather.gustSeed, 7)
        var tint = rainTint(alpha: 0.45, ambient: ambient)
        if weather.rain >= 0.5 {
            tint.w = rainHeavySplashAlpha
        }
        func shown(_ own: Double) -> SIMD4<Float> {
            guard reduceMotion else { return tint }
            return SIMD4<Float>(tint.x, tint.y, tint.z, tint.w * rainPulseAlpha(time: animTime, own: own))
        }
        var list: [SpriteInstance] = []
        for index in 0..<count {
            if reduceMotion && index % 3 != 0 { continue }
            let own = unit(SeededRandom.hash(key, Int64(index)))
            let progress = fallTime / rainSplashTime + own
            let cycle = progress.rounded(.down)
            let frame = min(2, Int((progress - cycle) * 3))
            let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
            let pick = SeededRandom.hash(SeededRandom.hash(key, turn), Int64(index))
            let column = unit(pick) * width
            var x = (column - whole).truncatingRemainder(dividingBy: width)
            if x < 0 { x += width }
            guard RainLook.isWater(unit(SeededRandom.hash(pick, 0x57)), x: x + whole, seam: seam) else { continue }
            let top = geometry.top(y: -Double(1 + index % 4), height: Double(size.height))
            let rect = SIMD4<Float>(Float(x.rounded(.down)), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .rainSplash, frame: frame, rect: rect, tint: shown(own), flipped: false))
        }
        // The ridges: one splash per roof in a light rain, two in a heavy one.
        let perRoof = weather.rain >= 0.5 ? 2 : 1
        for prop in props where prop.plane == .world {
            guard let ridge = rainRidges[prop.sprite] else { continue }
            let left = prop.x - whole
            guard geometry.isVisible(left: left, width: Double(prop.width)) else { continue }
            let roofTop = geometry.top(y: prop.y, height: Double(prop.height))
            let roofKey = SeededRandom.hash(key, Int64(prop.id) &+ 1000)
            for index in 0..<perRoof {
                let own = unit(SeededRandom.hash(roofKey, Int64(index)))
                if reduceMotion && (index + prop.id) % 3 != 0 { continue }
                let progress = fallTime / rainSplashTime + own
                let cycle = progress.rounded(.down)
                let frame = min(2, Int((progress - cycle) * 3))
                let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
                let pick = SeededRandom.hash(SeededRandom.hash(roofKey, turn), Int64(index))
                var dx = ridge.x0 + (unit(pick) * Double(ridge.x1 - ridge.x0 + 1)).rounded(.down)
                if prop.flipped { dx = Double(prop.width - 1) - dx }
                guard RainLook.isWater(unit(SeededRandom.hash(pick, 0x57)), x: prop.x + dx, seam: seam) else {
                    continue
                }
                let rect = SIMD4<Float>(Float((left + dx).rounded(.down)) - 2, Float(roofTop) + Float(ridge.row) - 2,
                                        Float(size.width), Float(size.height))
                list.append(SpriteInstance(sprite: .rainSplash, frame: frame, rect: rect, tint: shown(own),
                                           flipped: false))
            }
        }
        return list
    }

    /// Step 3 (the critic's M5): a splash's alpha in a heavy rain (0.5 and more).
    static let rainHeavySplashAlpha: Float = 0.7

    /// The roofs' ridges (the sprites' top rows, chimneys left out): its first and last column and its row from the
    /// sprite's top, unflipped. Step 3 (the critic's M5): the big house and the tavern as well as the cottages.
    static let rainRidges: [SpriteID: (x0: Double, x1: Double, row: Int)] = [
        .house: (14, 43, 4), .houseB: (14, 43, 4), .houseC: (14, 43, 4),
        .bigHouse: (22, 47, 5), .tavern: (37, 64, 6),
    ]

    /// Build 3 step 2 (the two rains): the ash's three depths west of the outermost standing wall: the plane, how fast
    /// it falls (game px/s; the rain falls ten times as fast), how many at full rain, its size (`ashFlake` frames 0-3
    /// small, 4-7 middling, 8-11 big) and its alpha. Step 3 (the critic's H2, the director's call 4): twice as many
    /// (the eye needs thirty or more on screen to read "falling"), hard clumps at about 0.8 alpha (`ashAlphaCap`: the
    /// ash is not rain, and its cap is not the rain's).
    static let ashDepths: [(plane: Plane, speed: Double, count: Int, size: Int, alpha: Float)] = [
        (.near, 13, 60, 0, 0.7), (.world, 19, 40, 1, 0.8), (.foreground, 28, 20, 2, 0.85),
    ]
    static let ashAlphaCap: Float = 0.85
    /// How far a flake drifts sideways per second in a wind of 1 beyond a calm's (game px/s), how far it sways as it
    /// tumbles in a whole wind, and how many tumble steps it turns a second in still air and in a wind of 1 more.
    static let ashDrift = 30.0
    /// How far a flake leans further downwind in a gust of 1 above the steady wind (game px): a gust leans the ash a
    /// few pixels, never so fast that a flake runs against the wind as it eases.
    static let ashGustReach = 6.0
    static let ashSway = 2.0
    static let ashTumble = (still: 2.0, wind: 5.0)
    /// The wind under which ash falls straight (a calm day's).
    static let ashCalm = 0.12
    /// Ash by day and by night, mixed by `rainShade` like the rain. Step 3 (the director's call 1): by day a warm soot,
    /// the one dark thing that falls. Step 4 (the director's call 1 of 07:27, "ash is never snow"): at night the flake's
    /// sprite is near black (`ashNightShade`), so it hides the blue sky behind it, and its emissive copy of
    /// `ashNightWarm × ashNightGlow` (× the night's share) gives it a warm ash grey with no blue in it, only a small step
    /// over the sky (the glow quad keeps 40 % of the hue, so the warm input comes out about 1 : 0.8 : 0.6). The pale
    /// copy of step 3 made snow.
    static let ashDayShade = SIMD3<Float>(0.30, 0.27, 0.26)
    static let ashNightShade = SIMD3<Float>(0.04, 0.035, 0.03)
    static let ashNightWarm = SIMD3<Float>(1.0, 0.5, 0.0)
    static let ashNightGlow: Float = 0.28
    /// The far depth's copy a little stronger: the near plane's haze lays the night's blue air over its body.
    static let ashNearNightLift: Float = 1.2
    /// The near depth's flakes stay this far east of the bank's edge (the face of its sheet on fog A): never drawn dark
    /// into the bank. The lane's depth falls under the bank's lane sheet, its night copy over it.
    static let ashBankFace = 24.0
    /// Step 3 (the director's idea, call 3): some flakes are born embers, decided by their index once: for the first
    /// `emberLife` of the fall a point of fire that dies to the grey flake, which grows in as the ember dies; it never
    /// reaches the ground glowing. Step 4 (the director's call 1 of 07:27, the critic's H1, "the embers carry the
    /// night"): one flake in four by day and one in three at night (`emberShare`); its life a third of the fall by day
    /// and 0.45 at night; a 2 x 2 point for its first 15 % by day and 30 % at night (`emberBig`), then one pixel. The
    /// point goes out as window glass (`ashFlake` frames 15 and 14, painted in the glass ink, the whole 5 x 5 cell as
    /// its source), so its colour arrives as it is: fire gold, the torch's orange, a deep red, then nothing
    /// (`emberHeat`; the gold is a deep one, low in blue, because the night's grade takes a fifth of every colour's
    /// saturation). Its body (frames 13 and 12, the day's orange, the same pixels as the point): on the foreground,
    /// which is drawn over the emissive pass, it takes the day's share only (`rainShade`), so at night no dark body lies
    /// over its light (the critic's H1 (a)); on the near and the lane's planes the body is drawn before the emissive
    /// pass and lies under the point: it hides the blue night sky behind those very pixels, never the light, and fades
    /// faster than the light does (1 - life against 1 - life²), so the point is never darker than the sky around it. A
    /// glass point added over the open blue sky could not stay fire coloured after the grade. No ember under Reduce
    /// Motion (it would pulse in place).
    /// b3-wind: build 3 step 5 (the director's call 2 of 11:07, the critic's H1 (a)): at night two flakes in five are
    /// born embers, they burn for 0.6 of the fall and stay two by two for their first 45 % (3 or 4 sparks burn in any
    /// third of the screen); by day the 2 x 2 phase is a quarter of the life (M-b: at 15 % no day frame showed one).
    static let emberShare = (day: 0.25, night: 0.4)
    static let emberLife = (day: 1.0 / 3, night: 0.6)
    static let emberBig = (day: 0.25, night: 0.45)
    /// b3-wind (step 5, H1 (b)): the 2 x 2 point is one hot core pixel (its top right, `emberFrames.point`'s pixel) in
    /// the gold × `emberCore` over three pixels of the torch's orange, so a value step stays inside the point after
    /// the night's grade. The core goes out as a second glass quad over the point (the emissive pass adds), coloured
    /// the difference (`emberCoreAdd`), so the core pixel arrives as the gold × 1.6.
    static let emberCore: Float = 1.6
    static var emberCoreAdd: SIMD3<Float> { emberGold * emberCore - emberColor }
    /// b3-wind (step 5, H1 (c)): a burning ember's grey flake does not grow in before this share of its life, so it
    /// burns in no dark clump; then it grows to the whole grey flake as the ember dies.
    static let emberGreyFrom: Float = 0.5
    /// Gate fix (round lh-b3w-42: ten embers in the night sky, three fire pixels): the night's grade in rain keeps
    /// about 0.57 of a colour's saturation (pulling blue up toward the luma, which green rules) and tints it cold, so the
    /// fire is low in green and has almost no blue, a little stronger, and its body (under the point, on the near and
    /// the lane's planes) fades as the light does (1 - life², `emberBodyAlpha`): it hides the blue sky behind the
    /// point while the point burns, and the light always outweighs what the body takes from the sky, so the pixel is
    /// never darker than the sky around it.
    static let emberGold = SIMD3<Float>(1.0, 0.48, 0.02)
    static let emberColor = SIMD3<Float>(1.0, 0.34, 0.02)
    static let emberRed = SIMD3<Float>(0.62, 0.09, 0.03)
    static let emberGlow: Float = 1.3
    /// The ember body's alpha at `life` (0 born ... 1 out), under the ash's cap: it fades as the light does.
    static func emberBodyAlpha(life: Float) -> Float {
        let t = max(0, min(1, life))
        return min(ashAlphaCap, 1 - t * t)
    }
    static let emberBody = SIMD3<Float>(0.85, 0.28, 0.12)
    /// The ember's frames: its body by day (one pixel, two by two), its glass point (one pixel, two by two).
    static let emberFrames = (body: 12, bigBody: 13, point: 14, bigPoint: 15)

    /// A day value and a night value mixed by the night's share (0 by day ... 1 at night).
    static func byNight(_ pair: (day: Double, night: Double), _ night: Float) -> Double {
        pair.day + (pair.night - pair.day) * Double(max(0, min(1, night)))
    }

    /// The ember's colour at `life` (0 born ... 1 out): fire gold, the torch's orange at half its life, a deep red at
    /// the end, its strength falling as 1 - life², so the red still shows before it is gone.
    static func emberHeat(life: Float) -> SIMD3<Float> {
        let t = max(0, min(1, life))
        var hue = emberColor + (emberRed - emberColor) * ((t - 0.5) / 0.5)
        if t < 0.5 {
            hue = emberGold + (emberColor - emberGold) * (t / 0.5)
        }
        return hue * (1 - t * t)
    }

    /// A flake's tint in this air.
    static func ashTint(alpha: Float, ambient: AmbientSample) -> SIMD4<Float> {
        let shade = rainShade(ambient)
        let rgb = ashNightShade + (ashDayShade - ashNightShade) * shade
        return SIMD4<Float>(rgb.x, rgb.y, rgb.z, min(ashAlphaCap, alpha))
    }

    /// Whether the flake of this index on this depth's key is born an ember, in an air of this night's share.
    static func isEmber(key: UInt64, index: Int, night: Float) -> Bool {
        unit(SeededRandom.hash(key ^ 0x454D_4252, Int64(index))) < byNight(emberShare, night)
    }

    /// How far a flake has moved sideways after `falling` seconds (game px): the steady wind carries it at `ashDrift`
    /// beyond a calm's, the wind of the moment above the steady one leans it by at most `ashGustReach`, and it sways as
    /// it tumbles (by the steady wind). So it always goes the steady wind's way, faster in a gust, and falls straight
    /// in a calm.
    static func ashSideways(falling: Double, own: Double, wind: Double, mean: Double) -> Double {
        let beyond = max(0, abs(mean) - ashCalm)
        let steady = beyond * (mean < 0 ? -1 : 1) * ashDrift * falling
        let gust = (wind - mean) * ashGustReach * min(1, max(0, abs(wind) - ashCalm) / 0.1)
        let sway = ashSway * min(1, beyond / 0.3) * sin(falling * 2.3 + own * 2 * Double.pi)
        return steady + gust + sway
    }

    /// The ash's flakes on one depth's plane, each a pure function of its index and the time: slow, drifting sideways
    /// with the wind where it falls (none in a calm: it falls straight) and tumbling through its four frames, faster in
    /// a wind. A flake falls only where the rain is not water (`RainLook`), so the ash thins in over the band west of
    /// the outermost standing wall. No streak and no splash. Step 3: warm soot by day, pale at night with a faint copy
    /// in the emissive pass, one in six born an ember, the near depth kept out of the bank; with Reduce Motion a third
    /// of them stand and fade in place. Returns the sprites and the emissive copies (the caller adds them where they
    /// belong in the draw order).
    private static func ashFlakes(depth: Int, animTime: Double, reduceMotion: Bool, ambient: AmbientSample,
                                  seam: Double, bankEdge: Double,
                                  geometry: Geometry) -> (sprites: [SpriteInstance], glow: [EmissiveInstance]) {
        let weather = geometry.weather
        let entry = ashDepths[depth]
        let count = rainCount(entry.count, rain: weather.rain)
        guard count > 0 else { return ([], []) }
        let fallTime = reduceMotion ? 0 : animTime
        let size = SpriteID.ashFlake.size
        let lowest: Double
        switch entry.plane {
        case .foreground: lowest = Double(geometry.targetHeight)
        case .world: lowest = Double(geometry.groundRow + 2)
        default: lowest = Double(geometry.groundRow - 8)
        }
        let fall = lowest + Double(size.height)
        let margin = 24.0
        let span = Double(geometry.targetWidth) + 2 * margin
        let whole = geometry.whole(entry.plane)
        let lane = geometry.whole(.world)
        let tint = ashTint(alpha: entry.alpha, ambient: ambient)
        let day = rainShade(ambient)
        let night = 1 - day
        // Step 4: the foreground is drawn over the emissive pass, so at night its flake could only be a dark speck over
        // its own warm copy: it fades out with the day, and the near and the lane's depths carry the night's ash.
        let body: Float = entry.plane == .foreground ? day : 1
        let warm = ashNightWarm * (ashNightGlow * (depth == 0 ? ashNearNightLift : 1))
        let life = byNight(emberLife, night)
        let big = byNight(emberBig, night)
        let key = SeededRandom.hash(weather.gustSeed ^ 0x41_5348, Int64(depth + 1))
        var list: [SpriteInstance] = []
        var glow: [EmissiveInstance] = []
        for index in 0..<count {
            if reduceMotion && index % 3 != 0 { continue }
            let own = unit(SeededRandom.hash(key, Int64(index)))
            let speed = entry.speed * (0.8 + 0.4 * own)
            let progress = fallTime * speed / fall + own
            let cycle = progress.rounded(.down)
            let share = progress - cycle
            let falling = share * fall / speed
            let y = share * fall - Double(size.height)
            let turn = Int64(max(-1.0e15, min(1.0e15, cycle)))
            let pick = SeededRandom.hash(SeededRandom.hash(key, turn), Int64(index))
            var x = (unit(pick) * span - whole).truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            // Ash or water, decided once at the column it starts from (no flake blinks out in mid-air); a flake that
            // drifts toward the wall fades as the water's share grows, and is gone at the wall.
            let start = x - margin + lane
            guard !RainLook.isWater(unit(SeededRandom.hash(pick, 0x41)), x: start, seam: seam) else { continue }
            let wind = Weather.wind(at: start, weather, time: fallTime)
            x += ashSideways(falling: falling, own: own, wind: wind, mean: weather.mean)
            x = (x.truncatingRemainder(dividingBy: span) + span).truncatingRemainder(dividingBy: span) - margin
            if depth == 0 && x + lane < bankEdge + ashBankFace { continue }
            var fade = Float(1 - RainLook.waterShare(x: x + lane, seam: seam))
            guard fade > 0.02 else { continue }
            if reduceMotion {
                fade *= rainPulseAlpha(time: animTime, own: own)
            }
            let tumble = Int(min(1.0e15, falling * (ashTumble.still + ashTumble.wind * abs(wind)) + own * 4)
                .rounded(.down)) % 4
            let frame = entry.size * 4 + tumble
            let flipped = own > 0.5
            let rect = SIMD4<Float>(Float(x.rounded(.down)), Float(y.rounded(.down)), Float(size.width),
                                    Float(size.height))
            var grey: Float = 1
            if !reduceMotion && isEmber(key: key, index: index, night: night) && share < life {
                let age = Float(share / life)
                let large = Double(age) < big
                // b3-wind (step 5): the 2 x 2 point in the torch's orange round its hot gold core.
                let strength = (1 - age * age) * emberGlow * fade
                let heat = large ? emberColor * strength : emberHeat(life: age) * (emberGlow * fade)
                let shown = emberBodyAlpha(life: age) * fade * (entry.plane == .foreground ? day : 1)
                if shown > 0.01 {
                    list.append(SpriteInstance(sprite: .ashFlake,
                                               frame: large ? emberFrames.bigBody : emberFrames.body, rect: rect,
                                               tint: SIMD4<Float>(emberBody.x, emberBody.y, emberBody.z, shown),
                                               flipped: false))
                }
                glow.append(EmissiveInstance(sprite: .ashFlake, plane: entry.plane, rect: rect,
                                             color: SIMD4<Float>(heat.x, heat.y, heat.z, 1), kind: .glass,
                                             source: SIMD4<Float>(0, 0, Float(size.width), Float(size.height)),
                                             frame: large ? emberFrames.bigPoint : emberFrames.point))
                if large {
                    let core = emberCoreAdd * strength
                    glow.append(EmissiveInstance(sprite: .ashFlake, plane: entry.plane, rect: rect,
                                                 color: SIMD4<Float>(core.x, core.y, core.z, 1), kind: .glass,
                                                 source: SIMD4<Float>(0, 0, Float(size.width), Float(size.height)),
                                                 frame: emberFrames.point))
                }
                grey = max(0, (age - emberGreyFrom) / (1 - emberGreyFrom))
            }
            // An ember's grey flake is drawn from its first moment (faint while it burns), so a flake never blinks into
            // the list: the same flakes stand in the list from one moment to the next. A foreground flake that rests at
            // night (`body` 0) is left out, so it costs no instance; `body` depends on the air alone, never on the
            // time, so the list still holds from one moment to the next.
            if body > 0.004 {
                list.append(SpriteInstance(sprite: .ashFlake, frame: frame, rect: rect,
                                           tint: SIMD4<Float>(tint.x, tint.y, tint.z, tint.w * fade * grey * body),
                                           flipped: flipped))
            }
            if night * fade * grey > 0.01 && entry.plane != .foreground {
                let ash = warm * (night * fade * grey)
                glow.append(EmissiveInstance(sprite: .ashFlake, plane: entry.plane, rect: rect,
                                             color: SIMD4<Float>(ash.x, ash.y, ash.z, 1), flipped: flipped,
                                             frame: frame))
            }
        }
        return (list, glow)
    }

    // MARK: Build 3 step 3, part B: the gust's leaves and dust (docs/POLISH.md 2 item 5; lane 3)

    /// Leaves in the air by the steady wind's step (`Weather.sailLevel`: calm, breeze, gusty, storm): none in a calm, a
    /// few in a breeze (while its small gusts are up), more on a gusty day and in a storm (while a gust is up where
    /// they fly; a storm keeps some aloft between its gusts). Puffs of the lane's dust only in a gusty day's or a storm's gusts.
    static let gustLeafCounts = [0, 3, 10, 18]
    static let gustDustCounts = [0, 0, 4, 5]
    /// A leaf crosses the screen at this speed plus `gustLeafDrive` × the steady wind (target px/s); a slot waits a
    /// share of its flight between flights. Step 4 (the critic's H3, Louis: "Baeume zum Wackeln, also Wind"; over the
    /// town the leaves were lost in front of roofs and crowns of their own value):
    /// - (a) a gust lifts them: each rises `gustLeafRise` (20 to 40 px, by its flight) over its first `gustLeafRiseTime`
    ///   seconds, easing out, then sinks `gustLeafSink` px/s, so most of its path runs over the roofs in the sky band;
    /// - (c) each slot its own speed (× `gustLeafPace`, 0.7 to 1.3 by its hash) and its own bob (3 to 6 px at 2.5 to
    ///   5.5 rad/s), so they never move as a conveyor;
    /// - (b) half are an autumn straw (`gustLeafAutumn`), lighter than every roof (the sprite: 6 x 5, a pale lit edge);
    /// - (d) in a storm each hard rise of the gust (`Weather.sinceGustRose`) lets 4 to 6 leaves of one crown go within
    ///   `gustBurstSpread` s, beside the slots (`gustBurstMost` at most).
    static let gustLeafSpeed = 50.0
    static let gustLeafDrive = 90.0
    static let gustLeafRise = (low: 20.0, high: 40.0)
    static let gustLeafRiseTime = 0.6
    static let gustLeafSink = 3.0
    static let gustLeafPace = (low: 0.7, high: 1.3)
    static let gustLeafBob = (low: 3.0, high: 6.0)
    static let gustLeafBobRate = (low: 2.5, high: 5.5)
    static let gustLeafAutumn = 0.5
    static let gustBurstLeast = 4
    static let gustBurstMost = 6
    static let gustBurstSpread = 0.3
    /// A puff of dust lives this long (s), drifting `gustDustReach` px downwind.
    static let gustDustLife = 1.2
    static let gustDustReach = 22.0

    /// Step 4 (the critic's H3 (d)): the leaves of a storm's burst in the air at this moment, for the gust at world x
    /// (the screen's middle): after each hard rise of the gust (`Weather.sinceGustRose`) 4 to 6 leaves, each starting
    /// within `gustBurstSpread` s of it, at its own pace, until it has crossed the screen's width. The key picks the
    /// crown they leave. Nil but in a storm (`Weather.sailLevel` 3) and without such a rise in the last three cells.
    static func gustBurst(_ weather: WeatherSample, at x: Double, time: Double, width: Double)
        -> (key: UInt64, leaves: [(mark: UInt64, along: Double, pace: Double, flight: Double)])? {
        guard Weather.sailLevel(weather.mean) == 3,
              let rose = Weather.sinceGustRose(at: x, weather, time: max(0, time)) else { return nil }
        let key = SeededRandom.hash(weather.gustSeed ^ 0x4255_5253, rose.cell)
        let count = gustBurstLeast
            + Int(unit(SeededRandom.hash(key, 2)) * Double(gustBurstMost - gustBurstLeast + 1))
        let speed = gustLeafSpeed + gustLeafDrive * abs(weather.mean)
        var leaves: [(mark: UInt64, along: Double, pace: Double, flight: Double)] = []
        for place in 0..<min(gustBurstMost, count) {
            let mark = SeededRandom.hash(key, Int64(16 + place))
            let along = rose.since - gustBurstSpread * unit(SeededRandom.hash(mark, 11))
            let pace = speed * (gustLeafPace.low + (gustLeafPace.high - gustLeafPace.low)
                                * unit(SeededRandom.hash(mark, 10)))
            let flight = (width + 40) / pace
            guard along >= 0, along < flight else { continue }
            leaves.append((mark: mark, along: along, pace: pace, flight: flight))
        }
        return leaves.isEmpty ? nil : (key: key, leaves: leaves)
    }

    /// How far the gust is up at world x, 0 ... 1: the wind there over the steady wind, against the day's whole gust.
    static func gustShare(at x: Double, _ weather: WeatherSample, time: Double) -> Double {
        guard weather.gust != 0 else { return 0 }
        let over = abs(Weather.wind(at: x, weather, time: time)) - abs(weather.mean)
        return min(1, max(0, over / max(0.05, abs(weather.gust))))
    }

    /// The leaves and dust a gust carries across the lane's plane, each a pure function of its slot and the time: a leaf
    /// sets off from the crown of a tree on the screen (else from the upwind edge, over the roofs), rises as the gust
    /// lifts it and tumbles downwind with a bob and a slow sink, in the trees' own greens or (step 4: one in two) an
    /// autumn straw; it shows while the gust is up where it flies and fades as the gust eases; a storm's hard rise lets a
    /// crown's leaves go in a burst. Never west of the outermost standing wall (the ash is the weather there), never
    /// with Reduce Motion, none in a calm.
    private static func gustLeaves(props: [Prop], animTime: Double, seam: Double,
                                   geometry: Geometry) -> [SpriteInstance] {
        let weather = geometry.weather
        let level = Weather.sailLevel(weather.mean)
        guard level > 0 else { return [] }
        let size = SpriteID.gustLeaf.size
        let width = Double(geometry.targetWidth)
        let lane = geometry.whole(.world)
        let ground = Double(geometry.groundRow)
        let downwind: Double = weather.mean < 0 ? -1 : 1
        let speed = gustLeafSpeed + gustLeafDrive * abs(weather.mean)
        // The crowns of the lane plane's trees on the screen, as screen x and the row of their upper third.
        var crowns: [(x: Double, y: Double)] = []
        for prop in props where prop.plane == .world && swaying.contains(prop.sprite) {
            let left = prop.x - lane
            guard geometry.isVisible(left: left, width: Double(prop.width)) else { continue }
            crowns.append((x: left + Double(prop.width) / 2,
                           y: geometry.top(y: prop.y, height: Double(prop.height)) + Double(prop.height) * 0.3))
        }
        let key = SeededRandom.hash(weather.gustSeed ^ 0x4C45_4146, 11)
        var list: [SpriteInstance] = []
        // One leaf `along` seconds into a flight that set off at (x0, y0), at its own pace and bob (`own` is its slot's or
        // its burst place's hash), with a share of the gust's alpha; nil when it is off the screen or west of the wall.
        func leaf(x0: Double, y0: Double, pick: UInt64, own: UInt64, along: Double, flight: Double,
                  pace: Double, alpha base: Double) -> SpriteInstance? {
            let rise = gustLeafRise.low + (gustLeafRise.high - gustLeafRise.low) * unit(SeededRandom.hash(pick, 7))
            let up = min(1, along / gustLeafRiseTime)
            let lift = rise * (1 - (1 - up) * (1 - up))
            let bob = gustLeafBob.low + (gustLeafBob.high - gustLeafBob.low) * unit(SeededRandom.hash(own, 8))
            let rate = gustLeafBobRate.low
                + (gustLeafBobRate.high - gustLeafBobRate.low) * unit(SeededRandom.hash(own, 9))
            let phase = unit(SeededRandom.hash(pick, 4)) * 2 * Double.pi
            let x = x0 + downwind * pace * along
            let sink = gustLeafSink * max(0, along - gustLeafRiseTime)
            let y = min(ground - 4, y0 - lift + sink + bob * sin(along * rate + phase))
            guard x > -Double(size.width), x < width, x + lane > seam else { return nil }
            // Fade in as it leaves the crown, out at the end of its flight.
            let alpha = base * min(1, along / 0.25) * min(1, (flight - along) / 0.4)
            guard alpha > 0.03 else { return nil }
            let tone = unit(SeededRandom.hash(pick, 5)) < gustLeafAutumn ? 2 : Int(unit(SeededRandom.hash(pick, 6)) * 2)
            let tumble = Int(min(1.0e15, along * (6 + 4 * abs(weather.mean)) + phase).rounded(.down)) % 4
            return SpriteInstance(sprite: .gustLeaf, frame: tone * 4 + tumble,
                                  rect: SIMD4<Float>(Float(x.rounded(.down)), Float(y.rounded(.down)),
                                                     Float(size.width), Float(size.height)),
                                  tint: SIMD4<Float>(1, 1, 1, Float(alpha)), flipped: downwind < 0)
        }
        for slot in 0..<gustLeafCounts[level] {
            let mark = SeededRandom.hash(key, Int64(slot))
            let own = unit(mark)
            let pace = speed * (gustLeafPace.low + (gustLeafPace.high - gustLeafPace.low)
                                * unit(SeededRandom.hash(mark, 10)))
            let flight = (width + 40) / pace
            // A short wait between flights (round lh-b3w-31: a leaf from a crown leaves the screen early, so a storm's
            // still showed one or two leaves).
            let cycle = flight * (1.05 + 0.35 * own)
            let clock = max(0, animTime) + own * cycle
            let turn = (clock / cycle).rounded(.down)
            let along = clock - turn * cycle
            guard along < flight else { continue }
            let pick = SeededRandom.hash(SeededRandom.hash(key, Int64(max(-1.0e15, min(1.0e15, turn)))), Int64(slot))
            // From the upwind edge it starts over the roofs (step 4); from a crown, where the gust takes it.
            var x0 = downwind > 0 ? -8 : width + 8
            var y0 = ground - 40 - 40 * unit(SeededRandom.hash(pick, 1))
            if !crowns.isEmpty && unit(SeededRandom.hash(pick, 2)) < 0.7 {
                let crown = crowns[Int(unit(SeededRandom.hash(pick, 3)) * Double(crowns.count)) % crowns.count]
                x0 = crown.x
                y0 = crown.y
            }
            let near = x0 + downwind * pace * along
            // A breeze's leaves ride its small gusts too (a lower threshold), so they are gone when it eases.
            let gust = gustShare(at: near + lane, weather, time: animTime)
            let alpha: Double
            if level == 1 {
                alpha = AmbientRamp.smoothstep((gust - 0.1) / 0.4)
            } else {
                let share = AmbientRamp.smoothstep((gust - 0.2) / 0.35)
                // A storm keeps two leaves in three aloft between its gusts (step 4: one in two read too few).
                alpha = max(level == 3 && slot % 3 != 2 ? 0.8 : 0, share)
            }
            if let item = leaf(x0: x0, y0: y0, pick: pick, own: mark, along: along, flight: flight, pace: pace,
                               alpha: alpha) {
                list.append(item)
            }
        }
        // Step 4 (the critic's H3 (d)): a storm's hard rise lets 4 to 6 leaves of one crown on the screen go at once.
        if !crowns.isEmpty, let burst = gustBurst(weather, at: lane + width / 2, time: animTime, width: width) {
            let crown = crowns[Int(unit(SeededRandom.hash(burst.key, 1)) * Double(crowns.count)) % crowns.count]
            for item in burst.leaves {
                // Each leaf a few pixels apart where it leaves the crown.
                let spread = (unit(SeededRandom.hash(item.mark, 12)) - 0.5) * 12
                if let found = leaf(x0: crown.x + spread, y0: crown.y + spread / 3, pick: item.mark, own: item.mark,
                                    along: item.along, flight: item.flight, pace: item.pace, alpha: 1) {
                    list.append(found)
                }
            }
        }
        // The lane's dust: puffs low over the cobbles, only while a gust is up there.
        let dustKey = SeededRandom.hash(key, 0x4455)
        for slot in 0..<gustDustCounts[level] {
            let own = unit(SeededRandom.hash(dustKey, Int64(slot)))
            let cycle = gustDustLife * (1.6 + own)
            let clock = max(0, animTime) + own * cycle
            let turn = (clock / cycle).rounded(.down)
            let along = clock - turn * cycle
            guard along < gustDustLife else { continue }
            let pick = SeededRandom.hash(SeededRandom.hash(dustKey, Int64(max(-1.0e15, min(1.0e15, turn)))),
                                         Int64(slot))
            let x = unit(pick) * width + downwind * gustDustReach * along / gustDustLife
            guard x + lane > seam else { continue }
            let share = AmbientRamp.smoothstep((gustShare(at: x + lane, weather, time: animTime) - 0.35) / 0.3)
            guard share > 0.03 else { continue }
            let frame = 12 + min(2, Int(along / gustDustLife * 3))
            let top = ground - Double(size.height) + 1 + Double(slot % 2)
            list.append(SpriteInstance(sprite: .gustLeaf, frame: frame,
                                       rect: SIMD4<Float>(Float(x.rounded(.down)), Float(top), Float(size.width),
                                                          Float(size.height)),
                                       tint: SIMD4<Float>(1, 1, 1, Float(0.85 * share)), flipped: downwind < 0))
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
            var intensity = source.intensity * (source.pictureGain ?? 1)   // world-3 fix 1: `LanternLook`
            if source.kind.fadesByDay {
                intensity *= torch
            } else if options.look == .two && SceneLayout.fadesToADayShare(source.kind) {
                // World-3 (1f): an open fire's pool falls to a quarter at noon, whole from the dusk.
                let day = SceneLayout.look2FireDayShare
                intensity *= day + (1 - day) * torch
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
            if options.look == .two && plane == .world {
                // World rebuild, fix round 2 (the critic: "a warm half disc sits cut off at the screen's left edge"):
                // inside the world's end the dark is whole, so a light there (the lord's lantern when he stands at
                // the end) fades with the end's own cover (`bankEnd`: whole for 20 px, gone by 92).
                intensity *= AmbientRamp.smoothstep((source.x - 20) / 72)
            }
            guard intensity > 0.01, radius > 0 else { continue }
            let centreX = source.x - geometry.whole(plane)
            guard geometry.isVisible(left: centreX - radius, width: 2 * radius) else { continue }
            // Build 3, POLISH pass 1 (lane 3): an open fire leans and gutters with the wind, one value
            // (`Weather.fireLean`): its pool moves downwind and down and dims; none in still air. After the culling,
            // so the wind never adds or takes a light.
            var lean = 0.0
            if options.look == .two && Weather.leans(source.kind) && !windproof(source) {
                lean = Weather.fireLean(x: source.x, geometry.weather, time: animTime,
                                        reduceMotion: options.reduceMotion)
                intensity *= 1 - Weather.fireGutter * abs(lean)
            }
            let centreY = Double(geometry.groundRow) - source.y + abs(lean) * Weather.fireLeanSink
            let circle = SIMD4<Float>(Float(centreX + lean * Weather.fireLeanReach), Float(centreY), Float(radius),
                                      Float(intensity))
            let rgba = SIMD4<Float>(color.x, color.y, color.z, 0)
            // World-2 fix round 1: a scene light may shape its pool (flat on the cobbles, a cone up a wall).
            var light = FrameLight(circle: circle, color: rgba, ellipseY: Float(source.squash ?? LightField.ellipseY),
                                   kind: source.kind, plane: plane)
            // World-2 fix round 2 (the critic's high 3): the architecture cuts it (an eave, a jamb, a corner).
            if let cut = source.clip {
                let whole = geometry.whole(plane)
                let ground = Double(geometry.groundRow)
                light.clip = SIMD4<Float>(Float(cut.x0 - whole), Float(ground - cut.y1),
                                          Float(cut.x1 - whole + 1), Float(ground - cut.y0 + 1))
            }
            list.append(light)
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
