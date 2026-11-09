/// The light lab (`-GWScene lightlab`, DESIGN.md "Milestone 1 in detail"): a grey stone wall and a floor with a grid
/// of lights in three radii and two colours (warm on the wall, cold near the floor), each with its glowing part, the
/// day's fog in front and behind. It judges falloff, bands, dither, bloom and fog. Built as a `FrameDesc`, so it runs
/// through exactly the renderer the world uses.
enum LightLabScene {
    /// Radii of the three columns (a fire arrow, the king's lantern, a little more than a brazier).
    static let radii: [Double] = [22, 40, 64]
    static let warm = SIMD3<Float>(1.0, 0.62, 0.26)
    static let cold = SIMD3<Float>(0.46, 0.62, 1.0)
    /// Column centres as shares of the visible width.
    static let columns: [Double] = [0.17, 0.48, 0.81]
    /// Heights above the ground line of the warm row and the cold row.
    static let warmHeight = 104.0
    static let coldHeight = 20.0

    static func frame(clock: DayClock, pixelScale: PixelScale, options: FrameOptions, animTime: Double) -> FrameDesc {
        let scale = pixelScale.scale
        let targetWidth = pixelScale.targetWidth
        let targetHeight = pixelScale.targetHeight
        let groundRow = Camera.groundRow(targetHeight: targetHeight)
        let groundDeviceY = Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight, scale: scale)
        let camera = Camera(focusX: 0, pixelScale: pixelScale)
        let offsets = camera.offsets(scale: scale)
        let ambient = AmbientRamp.sample(at: clock.hour)

        var world: [SpriteInstance] = []
        let grey = SIMD4<Float>(0.96, 0.96, 0.96, 1)
        let wall = SpriteID.castleWall.size
        for row in [1, 0] {
            var x = 0
            while x < targetWidth {
                let top = groundRow - wall.height * (row + 1)
                let rect = SIMD4<Float>(Float(x), Float(top), Float(wall.width), Float(wall.height))
                world.append(SpriteInstance(sprite: .castleWall, frame: 0, rect: rect, tint: grey, flipped: false))
                x += wall.width
            }
        }
        let floor = SpriteID.ground.size
        var floorX = 0
        while floorX < targetWidth {
            let rect = SIMD4<Float>(Float(floorX), Float(groundRow), Float(floor.width), Float(floor.height))
            world.append(SpriteInstance(sprite: .ground, frame: 0, rect: rect, tint: SIMD4<Float>(1, 1, 1, 1),
                                        flipped: false))
            floorX += floor.width
        }

        var lights: [FrameLight] = []
        var emissives: [EmissiveInstance] = []
        let rows: [(height: Double, color: SIMD3<Float>, sprite: SpriteID)] = [
            (warmHeight, warm, .brazierFlame), (coldHeight, cold, .lanternGlass),
        ]
        for row in rows {
            for (index, share) in columns.enumerated() {
                let cx = (pixelScale.visibleColumns * share).rounded()
                let cy = Double(groundRow) - row.height
                let circle = SIMD4<Float>(Float(cx), Float(cy), Float(radii[index]), 1)
                let color = SIMD4<Float>(row.color.x, row.color.y, row.color.z, 0)
                lights.append(FrameLight(circle: circle, color: color, ellipseY: Float(LightField.ellipseY),
                                         kind: .lantern))
                let size = row.sprite.size
                let left = Int(cx) - size.width / 2
                let top = Int(cy) - size.height / 2
                let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
                let glow = SIMD4<Float>(row.color.x, row.color.y, row.color.z, 1)
                emissives.append(EmissiveInstance(sprite: row.sprite, plane: .world, rect: rect, color: glow))
            }
        }

        var fog: [FogLayer] = []
        var fogSprites: [Plane: [SpriteInstance]] = [:]
        if options.effects.fog {
            // The world's fog layers (the same density and drift), so the lab judges the fog the scene shows.
            fog = FrameBuilder.fogLayers(ambient: ambient, animTime: animTime, reduceMotion: options.reduceMotion)
            for layer in fog {
                let baseY = layer.plane == .fogA ? FrameBuilder.fogYA : FrameBuilder.fogYB
                fogSprites[layer.plane] = fogStrips(layer, baseY: baseY, groundRow: groundRow, targetWidth: targetWidth)
            }
        }

        var planes: [PlaneLayer] = []
        for plane in Plane.allCases {
            let sprites = plane == .world ? world : (fogSprites[plane] ?? [])
            planes.append(PlaneLayer(offset: offsets[plane.rawValue], sprites: sprites))
        }
        let spriteCount = planes.reduce(0) { $0 + $1.sprites.count }
        let counts = FrameCounts(sprites: spriteCount, actors: 0, emissives: emissives.count, lights: lights.count)

        return FrameDesc(scale: scale,
                         physicalWidth: pixelScale.physicalWidth,
                         physicalHeight: pixelScale.physicalHeight,
                         targetWidth: targetWidth,
                         targetHeight: targetHeight,
                         groundRow: groundRow,
                         groundDeviceY: groundDeviceY,
                         hour: clock.hour,
                         phase: clock.phase,
                         cameraX: camera.x,
                         kingX: 0,
                         kingScreenX: 0,
                         planes: planes,
                         actors: [],
                         lights: lights,
                         emissives: emissives,
                         fog: fog,
                         ambient: ambient,
                         skyTop: ambient.skyTop,
                         skyBottom: ambient.skyBottom,
                         starAlpha: 0,
                         bankEdge: -1000,
                         bankAmbientScale: Float(DarknessBank.ambientScale),
                         lightStyle: options.lightStyle,
                         lightBands: FrameBuilder.lightBands,
                         bloom: options.effects.bloom,
                         debugLights: options.debugLights,
                         counts: counts)
    }

    /// Fog strips across the target, moved by the layer's drift in whole game pixels (the lab's camera stands at 0).
    static func fogStrips(_ layer: FogLayer, baseY: Double, groundRow: Int, targetWidth: Int) -> [SpriteInstance] {
        let size = SpriteID.fogStrip.size
        let tile = Double(size.width)
        let drift = Double(layer.drift).rounded(.down).truncatingRemainder(dividingBy: tile)
        let top = Double(groundRow) - baseY - Double(size.height)
        let tint = SIMD4<Float>(layer.color.x, layer.color.y, layer.color.z, layer.density)
        var list: [SpriteInstance] = []
        var index = -1
        while Double(index) * tile - drift < Double(targetWidth) + tile {
            let left = Double(index) * tile - drift
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(SpriteInstance(sprite: .fogStrip, frame: 0, rect: rect, tint: tint, flipped: index % 2 != 0))
            index += 1
        }
        return list
    }
}
