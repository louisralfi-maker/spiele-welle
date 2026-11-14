import Foundation

extension PlaneOffset {
    /// A plane's offset from its own offset `o` (game px) at a scale that may be fractional (the hall stage, stage
    /// lane: its window plane at parallax 0.3, its near pillars at 1.25, and the eased move into the audience).
    init(plane: Plane, offset o: Double, zoom: Double) {
        let n = o.rounded(.down)
        let f = o - n
        self.plane = plane
        offset = o
        whole = Int(n)
        fraction = f
        deviceShift = Int((f * zoom).rounded())
    }
}

/// What the hall's frame is built from (the hall stage's own `FrameBuilder`; stage lane, 14.11.2026).
struct HallFrameInput {
    var state: GameState
    var balance: Balance
    var scene: HallScene
    var court: CourtScene
    var figures: [DrawnFigure]
    var specs: [HallFigureSpec]
    var lord: LordIdentity
    var pixelScale: PixelScale
    var options: FrameOptions
    /// The hour's ambient outdoors, the weather applied (the windows show it).
    var ambient: AmbientSample
    var weather: WeatherSample
    var animTime: Double
}

/// The great hall's frame (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world", SPRITES.md "The
/// great hall as a stage", docs/REVIEW-look-2.md 2.6, 2.7, H9, H10). Pure: the same input gives the same frame.
///
/// Planes, back to front: the hour's sky and its stars (the windows' glass is transparent), the Weltmauer on the far
/// plane at parallax 0.3, the hall with its plaster patches, the houses' banners, the benches, the throne and the
/// lectern on the world plane, the near arcade's pillars in front of everything at 1.25. The figures by their row,
/// the lord last. Light is the realm's state: the hearth's fire and its long pool follow the hearth's strength, the
/// candles beside a bench burn while someone waits on it, the chandeliers while the court sits by day, the door's
/// torches from the dusk; by day soft shafts fall from the two tall windows with dust in them (frozen under Reduce
/// Motion). The hall has its own ambient, dimmer than the open air, and its upper wall fades into the roof's dark.
enum HallFrames {
    /// The hall's ambient against the open air's: by day the windows light it at this share, at night a little more
    /// of the moon's (the hall is darker than outdoors by day, about as dark at night).
    static let dayShare: Float = 0.58
    static let nightShare: Float = 0.82
    /// By day the hall's ambient warms this far toward the stone and oak's bounce.
    static let bounceWarm = SIMD3<Float>(1.0, 0.9, 0.78)
    static let bounceShare: Float = 0.3
    /// At night the hall keeps a dim warm fill of its hearth and candles (the old cut-away rooms' colour) against the
    /// moon's blue: this share of the night ambient, at this level.
    static let nightWarm: Float = 0.45
    static let nightFillLevel: Float = 0.3
    /// The night's pull toward blue inside, against outdoors.
    static let nightPull: Float = 0.6
    /// The upper wall's ramp into the roof's dark: its strength and the hall row where it ends.
    static let rampStrength: Float = 0.62
    static let rampEndRow = 118
    /// The shafts: their colour, their strength at full sun, the floor pool where they land.
    static let shaftColor = SIMD3<Float>(1.0, 0.92, 0.76)
    static let goldenShaft = SIMD3<Float>(1.0, 0.70, 0.40)
    static let shaftStrength: Float = 0.42
    static let shaftPoolRow = 186
    static let motesPerShaft = 11
    /// A near pillar fades to this while the lord stands behind it: fully from `pillarFade`'s lower bound (game px
    /// on screen between the pillar's middle and his), back to whole at its upper bound.
    static let pillarSeen = 0.32
    static let pillarFade: ClosedRange<Double> = 26...42
    /// The great fire's frames a second.
    static let fireRate = 8.0
    /// The one who has the word stands in a warm pool of this radius.
    static let speakerPool = 30.0

    /// The hall's interior light for the hour's outdoor ambient: dimmer by day, warmed a little by the stone and oak.
    static func interior(_ ambient: AmbientSample, groundRow: Int) -> InteriorLight {
        let world = Look2.worldAmbient(ambient)
        let night = Look.nightness(ambient)
        let share = dayShare + (nightShare - dayShare) * night
        let warm = world + (world * bounceWarm - world) * (bounceShare * (1 - night))
        let fillPeak = max(0.001, max(Look2.interior.x, max(Look2.interior.y, Look2.interior.z)))
        let fill = Look2.interior / fillPeak * nightFillLevel
        let lit = warm * share
        let ambient = lit + (fill - lit) * (nightWarm * night)
        let row = groundRow - (HallLayout.floorRow - rampEndRow)
        return InteriorLight(ambient: ambient, nightPull: nightPull, rampStrength: rampStrength,
                             rampEndRow: Float(row))
    }

    /// How strong the day's shafts are now (0 ... 1) and which way they fall: in the morning the sun stands right of
    /// the hall and they slant down to the left (the painted beam mirrored), in the afternoon down to the right; none
    /// round noon (the sun stands over the roof) and none at night; clouds and rain take them.
    static func shafts(hour: Double, ambient: AmbientSample, weather: WeatherSample)
        -> (morning: Double, afternoon: Double) {
        func smooth(_ a: Double, _ b: Double, _ x: Double) -> Double {
            let t = min(1, max(0, (x - a) / (b - a)))
            return t * t * (3 - 2 * t)
        }
        let day = Double(Look.daylight(ambient)) * smooth(0, 0.3, Double(ambient.sunHeight))
        let sky = 1 - 0.85 * weather.cover
        let rise = smooth(6.3, 7.6, hour)
        let set = 1 - smooth(17.2, 18.6, hour)
        let morning = (1 - smooth(10.4, 11.9, hour)) * rise
        let afternoon = smooth(12.1, 13.6, hour) * set
        return (morning * day * sky, afternoon * day * sky)
    }

    /// The figures as drawn now: the layout's places smoothed (`HallScene.drawn`), the audience's walker on stage,
    /// the talking member held and gesturing, the leavers walking out. The hall answers its lord: for a moment after
    /// he came in (`since`) the door's guards stand straight and the waiting turn their heads to him; whom he passes
    /// close looks at him, and a seated petitioner he passes bows his head.
    static func drawnFigures(_ specs: [HallFigureSpec], scene: HallScene, court: CourtScene, residents: [String],
                             lordX: Double, since: Double = 60, animTime: Double) -> [DrawnFigure] {
        var list: [DrawnFigure] = []
        let stageKey = court.audience.map { HallCourt.walkerKey($0, residents: residents) }
        let audience = court.audience != nil
        for spec in specs where spec.key != stageKey {
            let talking = court.talking == spec.who && spec.petition == nil && spec.who != "guard"
            let target = talking ? (court.talkX ?? spec.x) : spec.x
            let x = scene.drawn[spec.key] ?? target
            var facing = spec.facing
            var frame: Int
            var seated: SpriteID?
            var lift = spec.lift
            let near = abs(lordX - x)
            let toLord = lordX >= x ? 1 : -1
            if talking {
                frame = CourtFrames.talkFrame(spec.body, animTime: animTime, key: spec.key)
                facing = toLord
            } else if abs(x - target) > 0.75 {
                frame = CourtFrames.walkFrame(spec.body, x: x)
                facing = target > x ? 1 : -1
                lift = max(HallLayout.lift(at: x), spec.row == HallLayout.wallRow ? spec.lift : 0)
            } else if spec.walking {
                frame = CourtLayout.frame(spec.body, walking: true, walked: spec.walked, seconds: 0)
            } else if let strip = spec.seated {
                seated = strip
                frame = CourtFrames.seatedFrame(animTime: animTime, key: spec.key)
                if !audience && (since < HallCourt.greetSeconds || near < HallCourt.noticeDistance) {
                    facing = toLord
                    if near < HallCourt.bowDistance { frame = 1 }
                }
            } else if spec.who == "guard" {
                frame = CourtFrames.idleFrame(spec.body, animTime: animTime, key: spec.key)
                if since > 0.12 && since < HallCourt.straightenSeconds {
                    frame = spec.body.idle.lowerBound
                    lift += 1
                }
            } else {
                frame = CourtFrames.idleFrame(spec.body, animTime: animTime, key: spec.key)
                let greets = spec.petition != nil && since < HallCourt.greetSeconds
                if !audience && (greets || near < HallCourt.noticeDistance) { facing = toLord }
            }
            list.append(DrawnFigure(who: spec.who, key: spec.key, body: spec.body, x: x, y: lift, facing: facing,
                                    frame: frame, alpha: 1, look: spec.look, petition: spec.petition,
                                    talking: talking, seated: seated))
        }
        if let session = court.audience, let body = Speakers.speaker(session.speaker)?.body {
            let x = session.walkerX
            let frame: Int
            if session.isWalking {
                frame = CourtFrames.walkFrame(body, x: x)
            } else if body.talk != nil {
                frame = CourtFrames.talkFrame(body, animTime: animTime, key: session.petitionID)
            } else {
                frame = CourtFrames.idleFrame(body, animTime: animTime, key: session.petitionID)
            }
            // From the bench's wall line or the dais down onto the walk line as he goes.
            let fromSpec = specs.first { $0.key == stageKey }
            let fromLift = fromSpec?.row == HallLayout.wallRow ? fromSpec?.lift ?? 0 : 0
            let span = max(1, abs(session.spotX - session.fromX))
            let share = min(1, abs(x - session.fromX) / span)
            let lift = max(HallLayout.lift(at: x), fromLift * (1 - share))
            list.append(DrawnFigure(who: session.speaker, key: stageKey ?? session.speaker, body: body, x: x,
                                    y: lift, facing: session.walkerFacing, frame: frame, alpha: 1,
                                    look: session.petitioner.look, petition: session.petitionID,
                                    talking: !session.isWalking))
        }
        for leaver in court.leavers {
            let frame = leaver.isWalking ? CourtFrames.walkFrame(leaver.body, x: leaver.x)
                : CourtFrames.idleFrame(leaver.body, animTime: animTime, key: leaver.who)
            list.append(DrawnFigure(who: leaver.who, key: "leaving:" + leaver.who, body: leaver.body, x: leaver.x,
                                    y: HallLayout.lift(at: leaver.x), facing: leaver.facing, frame: frame,
                                    alpha: leaver.alpha, look: leaver.look, petition: nil, talking: false))
        }
        return list
    }

    // MARK: - The frame

    private struct Geometry {
        let zoom: Double
        let left: Double
        let viewWidth: Double
        let targetWidth: Int
        let targetHeight: Int
        let groundRow: Int
        let physicalWidth: Int
        let physicalHeight: Int
        let offsets: [PlaneOffset]

        var groundDeviceY: Double { Double(physicalHeight) - Double(WorldLayout.groundRowsBelow) * zoom }

        func whole(_ plane: Plane) -> Double { Double(offsets[plane.rawValue].whole) }

        /// The target row of a hall row.
        func row(_ r: Int) -> Double { Double(groundRow - (HallLayout.floorRow - r)) }

        /// A rect on the world plane: a hall x (left edge) and a hall row (top).
        func rect(x: Double, row r: Int, size: PixelSize) -> SIMD4<Float> {
            SIMD4<Float>(Float(x.rounded(.down) - whole(.world)), Float(row(r)), Float(size.width), Float(size.height))
        }

        /// An actor's quad in device pixels: its anchor (bottom centre) at hall x, `lift` px above the walk line.
        func actor(_ sprite: SpriteID, x: Double, lift: Double) -> SIMD4<Float> {
            let size = sprite.size
            let world = offsets[Plane.world.rawValue]
            let anchor = ((x - Double(world.whole)) * zoom).rounded() - Double(world.deviceShift)
            let width = Double(size.width) * zoom
            let height = Double(size.height) * zoom
            let left = anchor - Double(size.width / 2) * zoom
            let bottom = (groundDeviceY - lift * zoom).rounded()
            return SIMD4<Float>(Float(left), Float(bottom - height), Float(width), Float(height))
        }

        func onScreen(_ rect: SIMD4<Float>) -> Bool {
            rect.x + rect.z >= 0 && rect.x <= Float(physicalWidth)
        }
    }

    static func build(_ input: HallFrameInput) -> FrameDesc {
        let s = input.state
        let options = input.options
        let ambient = input.ambient
        let animTime = input.animTime
        let reduceMotion = options.reduceMotion
        let pixelScale = input.pixelScale
        let walkLeft = input.scene.camera?.x ?? 0
        let framing = HallFraming.framing(pixelScale, walkLeft: walkLeft, progress: input.scene.zoom)
        let targetScale = PixelScale(physicalWidth: pixelScale.physicalWidth, physicalHeight: pixelScale.physicalHeight,
                                     override: framing.targetScale)
        let zoom = framing.scale
        let left = framing.left
        let viewWidth = HallFraming.viewWidth(pixelScale, scale: zoom)
        var offsets: [PlaneOffset] = []
        for plane in Plane.allCases {
            let parallax: Double
            switch plane {
            case .sky: parallax = 0
            case .far: parallax = HallLayout.weltmauerParallax
            case .foreground: parallax = HallLayout.nearParallax
            default: parallax = 1
            }
            offsets.append(PlaneOffset(plane: plane, offset: left * parallax, zoom: zoom))
        }
        let groundRow = targetScale.targetHeight - WorldLayout.groundRowsBelow
        let g = Geometry(zoom: zoom, left: left, viewWidth: viewWidth, targetWidth: targetScale.targetWidth,
                         targetHeight: targetScale.targetHeight, groundRow: groundRow,
                         physicalWidth: pixelScale.physicalWidth, physicalHeight: pixelScale.physicalHeight,
                         offsets: offsets)
        let torch = min(1, max(0, Double(ambient.torchStrength)))
        let byDay = DayClock.phase(at: s.hour) == .day
        let strength = max(0, min(1, s.hearth / max(1, input.balance.hearthStrength)))
        let world = s.court?.world ?? []
        func flicker(_ seed: UInt64) -> FlickerSample {
            Flicker.sample(seed: seed, time: animTime, reduceMotion: reduceMotion)
        }

        var sprites: [[SpriteInstance]] = Array(repeating: [], count: Plane.allCases.count)
        var emissives: [EmissiveInstance] = []
        var lights: [FrameLight] = []
        let white = SIMD4<Float>(1, 1, 1, 1)
        func put(_ sprite: SpriteID, x: Double, row: Int, frame: Int = 0, plane: Plane = .world) {
            let rect = g.rect(x: x, row: row, size: sprite.size)
            sprites[plane.rawValue].append(SpriteInstance(sprite: sprite, frame: frame, rect: rect, tint: white,
                                                          flipped: false))
        }
        func glow(_ sprite: SpriteID, x: Double, row: Int, color: SIMD3<Float>, frame: Int = 0) {
            let rect = g.rect(x: x, row: row, size: sprite.size)
            guard rect.x + rect.z >= -1, rect.x <= Float(g.targetWidth) + 1 else { return }
            emissives.append(EmissiveInstance(sprite: sprite, plane: .world, rect: rect,
                                              color: SIMD4<Float>(color.x, color.y, color.z, 1), frame: frame))
        }
        func light(_ kind: LightKind, x: Double, row: Int, radius: Double, intensity: Double,
                   color: SIMD3<Float>? = nil, squash: Float = Float(LightField.ellipseY), seed: UInt64 = 0) {
            var radius = radius
            var intensity = intensity
            var rgb = color ?? kind.defaultColor
            if kind.flickers {
                let f = flicker(seed)
                intensity *= f.intensity
                radius += Double(f.radiusJitter)
                rgb = (rgb + f.colorShift).clamped(lowerBound: SIMD3<Float>(repeating: 0),
                                                   upperBound: SIMD3<Float>(repeating: 1))
            }
            guard intensity > 0.01, radius > 0 else { return }
            let cx = x - g.whole(.world)
            guard cx + radius >= 0, cx - radius <= Double(g.targetWidth) else { return }
            lights.append(FrameLight(circle: SIMD4<Float>(Float(cx), Float(g.row(row)), Float(radius),
                                                          Float(intensity)),
                                     color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 0), ellipseY: squash, kind: kind))
        }

        // The sky's stars (the windows are glass) and the Weltmauer on its plane.
        if ambient.starAlpha > 0.01 {
            let tile = SpriteID.starField.size
            var row = 0
            while row < g.targetHeight {
                var column = 0
                while column < g.targetWidth {
                    emissives.append(EmissiveInstance(sprite: .starField, plane: .sky,
                                                      rect: SIMD4<Float>(Float(column), Float(row), Float(tile.width),
                                                                         Float(tile.height)),
                                                      color: SIMD4<Float>(1, 1, 1, ambient.starAlpha)))
                    column += tile.width
                }
                row += tile.height
            }
        }
        let welt = SpriteID.weltmauer.size
        sprites[Plane.far.rawValue].append(SpriteInstance(
            sprite: .weltmauer, frame: 0,
            rect: SIMD4<Float>(Float(HallLayout.weltmauerLeft - g.whole(.far)), Float(g.row(HallLayout.weltmauerTop)),
                               Float(welt.width), Float(welt.height)),
            tint: white, flipped: false))

        // The hall, its wear, the houses' banners and the court's furniture.
        put(.greatHall, x: 0, row: 0)
        for (index, patch) in HallLayout.washPatches.enumerated() {
            put(.hallWash, x: patch.x, row: patch.row, frame: index)
        }
        for place in CourtFrames.houseBannerPlaces(world: world, flags: s.flags) where place < HallLayout.bannerXs.count {
            put(CourtFrames.houseBanners[place].sprite, x: HallLayout.bannerXs[place], row: HallLayout.bannerTop)
        }
        if world.contains("castle.hall.tapestry") {
            put(.tapestry, x: HallLayout.tapestry.x, row: HallLayout.tapestry.row)
        }
        if world.contains("castle.seren.lantern") {
            let size = SpriteID.serenLantern.size
            put(.serenLantern, x: HallLayout.serenLantern.x - Double(size.width / 2),
                row: HallLayout.serenLantern.row - size.height)
            light(.lantern, x: HallLayout.serenLantern.x, row: HallLayout.serenLantern.row - 10, radius: 18,
                  intensity: 0.8, color: CourtFrames.coldLight, seed: 0x5345_5245)
        }
        let bench = SpriteID.bench.size
        for cx in HallLayout.benches {
            put(.bench, x: cx - Double(bench.width / 2), row: HallLayout.wallRow - bench.height)
        }
        let throne = SpriteID.throne.size
        put(.throne, x: HallLayout.throneX - Double(throne.width / 2), row: HallLayout.daisRow - throne.height)
        let lectern = SpriteID.taxLectern.size
        put(.taxLectern, x: HallLayout.lecternX - Double(lectern.width / 2), row: HallLayout.daisRow - lectern.height)

        // The hearth: the great fire, or the small one when the hearth is low; its pool on the wall and on the flags.
        let fireSeed: UInt64 = 0x4841_4C4C
        let fireFlicker = Float(flicker(fireSeed).intensity)
        if strength >= HallLayout.smallFireBelow {
            let size = SpriteID.hallFire.size
            let rate = reduceMotion ? fireRate * Flicker.reducedRateScale : fireRate
            let frame = Int((max(0, animTime) * rate).rounded(.down)) % max(1, SpriteID.hallFire.frameCount)
            glow(.hallFire, x: HallLayout.hearthX - Double(size.width / 2),
                 row: HallLayout.fireBottomRow - size.height + 1,
                 color: SIMD3<Float>(repeating: (0.75 + 0.25 * Float(strength)) * fireFlicker), frame: frame)
        } else if strength > 0.01 {
            let size = SpriteID.hearthFire.size
            glow(.hearthFire, x: HallLayout.hearthX - Double(size.width / 2),
                 row: HallLayout.fireBottomRow - size.height + 1, color: SIMD3<Float>(repeating: fireFlicker))
        }
        if strength > 0.01 {
            light(.hearth, x: HallLayout.hearthLight.x, row: HallLayout.hearthLight.row,
                  radius: HallLayout.hearthRadius.base + HallLayout.hearthRadius.perStrength * strength,
                  intensity: 1.25 * (0.4 + 0.6 * strength), seed: fireSeed)
            // The long warm pool on the flags: a pool of its own kind (a hearth light would send embers up out of
            // the floor), in the fire's colour, scaled back up by the candle's share of look 2.
            light(.candle, x: HallLayout.floorPool.x, row: HallLayout.floorPool.row,
                  radius: HallLayout.floorPool.radius * (0.55 + 0.45 * strength), intensity: 1.05 * strength,
                  color: GamePalette.fireOrange, squash: Float(HallLayout.floorPool.squash), seed: fireSeed &+ 1)
        }
        let candle = GamePalette.fireWhite
        func candles(_ list: [(x: Double, row: Int)], seed: UInt64, share: Double = 1) {
            for (index, c) in list.enumerated() {
                let f = Float(flicker(seed &+ UInt64(index)).intensity * share)
                glow(.candleFlame, x: c.x - 1, row: c.row - 1, color: candle * f)
            }
        }
        candles(HallLayout.mantelCandles, seed: 0x4D41_4E54)
        candles(HallLayout.armsCandles, seed: 0x4152_4D53)
        light(.candle, x: HallLayout.armsLight.x, row: HallLayout.armsLight.row, radius: 14, intensity: 0.7,
              seed: 0x4152_4D53)
        candles(HallLayout.newelCandles, seed: 0x4E45_5745)
        for (index, c) in HallLayout.newelCandles.enumerated() {
            light(.candle, x: c.x, row: c.row, radius: 12, intensity: 0.6, seed: 0x4E45_5745 &+ UInt64(index))
        }
        // The chandeliers burn while the court sits (by day) and go out for the night.
        if byDay {
            for (index, cx) in HallLayout.chandeliers.enumerated() {
                let seed: UInt64 = 0x4348_414E &+ UInt64(index) &* 16
                candles(HallLayout.chandelierCandles.map { (x: cx + $0.x, row: $0.row) }, seed: seed)
                light(.candle, x: cx, row: HallLayout.chandelierRow, radius: 44, intensity: 0.55, seed: seed)
            }
        }
        // A stand's candles burn beside a bench while someone waits on it.
        let benches = HallCourt.occupiedBenches(input.specs)
        for (index, sx) in HallLayout.stands.enumerated() where benches.contains(index / 2) {
            let seed: UInt64 = 0x5354_414E &+ UInt64(index) &* 16
            candles(HallLayout.standCandles.map { (x: sx + $0.dx, row: $0.row) }, seed: seed)
            light(.candle, x: sx, row: HallLayout.standRow, radius: 26, intensity: 0.9, seed: seed)
        }
        // The door's torches from the dusk.
        if torch > 0.02 {
            for (index, t) in HallLayout.torches.enumerated() {
                let seed: UInt64 = 0x544F_5243 &+ UInt64(index)
                let f = Float(flicker(seed).intensity * torch)
                let size = SpriteID.flame.size
                glow(.flame, x: t.x - Double(size.width / 2), row: t.row - size.height + 1,
                     color: GamePalette.fireGold * f)
                light(.torch, x: t.x, row: t.row, radius: 34, intensity: 0.95 * torch, seed: seed)
            }
        }
        // By day the sun's shafts from the two tall windows, dust in them, and their light on the floor.
        let beams = shafts(hour: s.hour, ambient: ambient, weather: input.weather)
        let shaft = SpriteID.hallShaft.size
        // The low sun's gold in the morning's and the evening's shafts.
        let golden = min(1, max(0, ambient.warmth / 0.45))
        let shaftColor = HallFrames.shaftColor + (HallFrames.goldenShaft - HallFrames.shaftColor) * golden
        for (strengthShare, mirrored) in [(beams.morning, true), (beams.afternoon, false)] where strengthShare > 0.01 {
            let k = Float(strengthShare) * shaftStrength
            for (index, windowLeft) in HallLayout.windowLefts.enumerated() {
                let x = mirrored ? windowLeft - Double(shaft.width - 30) : windowLeft
                let rect = g.rect(x: x, row: HallLayout.shaftTop, size: shaft)
                emissives.append(EmissiveInstance(sprite: .hallShaft, plane: .world, rect: rect,
                                                  color: SIMD4<Float>(shaftColor.x * k, shaftColor.y * k,
                                                                      shaftColor.z * k, 1),
                                                  flipped: mirrored))
                let reach = HallLayout.shaftSlant * Double(shaftPoolRow - HallLayout.shaftTop)
                let poolX = windowLeft + 15 + (mirrored ? -reach : reach)
                light(.window, x: poolX, row: shaftPoolRow, radius: 30, intensity: 1.1 * Double(k),
                      color: shaftColor, squash: 2.6)
                // Dust drifting slowly down the beam (frozen under Reduce Motion).
                let time = reduceMotion ? 0 : animTime
                for mote in 0..<motesPerShaft {
                    let seed = UInt64(index * 97 + mote * 13 + (mirrored ? 7 : 0))
                    let phase = Particles.unit(seed, 1)
                    let speed = 0.012 + 0.01 * Particles.unit(seed, 2)
                    var along = (phase + time * speed).truncatingRemainder(dividingBy: 1)
                    if along < 0 { along += 1 }
                    let rowF = Double(HallLayout.shaftTop) + 8 + along * 96
                    let across = 4 + Particles.unit(seed, 3) * 22 + sin(time * 0.6 + phase * 6.28) * 1.5
                    let down = HallLayout.shaftSlant * (rowF - Double(HallLayout.shaftTop))
                    let mx = windowLeft + across + (mirrored ? -down : down)
                    let fade = Float(sin(along * Double.pi)) * (0.55 + 0.45 * Float(Particles.unit(seed, 4)))
                    let c = shaftColor * (k * 1.6 * fade)
                    let rect = SIMD4<Float>(Float(mx.rounded(.down) - g.whole(.world)), Float(g.row(Int(rowF))),
                                            1, 1)
                    emissives.append(EmissiveInstance(sprite: .hallMote, plane: .world, rect: rect,
                                                      color: SIMD4<Float>(c.x, c.y, c.z, 1)))
                }
            }
        }

        // The near arcade's pillars, in front of everything.
        let pillar = SpriteID.hallPillarNear.size
        // A pillar the lord stands behind lets him show through (it fades to `pillarSeen`), so the near arcade gives
        // depth as he walks past and never hides him where he stops.
        let lordAt = input.court.audience?.place == .throne ? HallLayout.throneX : input.scene.walker.x
        for p in HallLayout.nearPillars {
            let planeX = HallLayout.nearParallax * p - (HallLayout.nearParallax - 1) / 2 * viewWidth
            let x = (planeX - Double(pillar.width) / 2).rounded(.down) - g.whole(.foreground)
            guard x + Double(pillar.width) >= -1, x <= Double(g.targetWidth) + 1 else { continue }
            let apart = abs(HallLayout.nearParallax * (p - lordAt))
            let k = min(1, max(0, (apart - pillarFade.lowerBound) / (pillarFade.upperBound - pillarFade.lowerBound)))
            let alpha = Float(pillarSeen + (1 - pillarSeen) * k)
            sprites[Plane.foreground.rawValue].append(SpriteInstance(
                sprite: .hallPillarNear, frame: 0,
                rect: SIMD4<Float>(Float(x), Float(g.row(0)), Float(pillar.width), Float(pillar.height)),
                tint: SIMD4<Float>(1, 1, 1, alpha), flipped: false))
        }

        // The figures by their row (the dais and the wall line behind the walk line), then the lord.
        var actors: [ActorInstance] = []
        let glass = Float(0.5 + 0.5 * torch)
        func addActor(_ sprite: SpriteID, frame: Int, x: Double, lift: Double, facing: Int, alpha: Double = 1,
                      shade: Float = 1, emissive: Bool = false) {
            guard alpha > 0.003 else { return }
            let rect = g.actor(sprite, x: x, lift: lift)
            guard g.onScreen(rect) else { return }
            actors.append(ActorInstance(sprite: sprite, frame: frame, rect: rect,
                                        tint: SIMD4<Float>(shade, shade, shade, Float(min(1, alpha))),
                                        flipped: facing < 0, isEmissive: emissive, isLit: true))
        }
        let ordered = input.figures.enumerated().sorted { a, b in
            a.element.y != b.element.y ? a.element.y > b.element.y : a.offset < b.offset
        }.map(\.element)
        for figure in ordered {
            addActor(figure.sprite, frame: figure.frame, x: figure.x, lift: figure.y, facing: figure.facing,
                     alpha: figure.alpha)
            if figure.seated == nil, let strip = figure.body.glow {
                addActor(strip, frame: figure.frame, x: figure.x, lift: figure.y, facing: figure.facing,
                         alpha: figure.alpha, shade: glass, emissive: true)
            }
            if input.court.marks.contains(figure.who) && figure.petition == nil {
                let pulse = reduceMotion ? 1 : Int(max(0, animTime) / 0.6) % 2
                let height = Double(figure.sprite.size.height)
                addActor(.speakerMark, frame: pulse, x: figure.x + 2, lift: figure.y + height + 2, facing: 1,
                         alpha: figure.alpha, emissive: true)
            }
        }
        if let session = input.court.audience, session.phase != .approach {
            light(.candle, x: session.spotX, row: HallLayout.floorRow - 5, radius: speakerPool, intensity: 0.7,
                  color: GamePalette.fireGold)
        }
        if input.court.audience == nil && !AudienceRules.hall(s, catalog: .standard).isEmpty {
            let pulse = reduceMotion ? 1 : Int(max(0, animTime) / 0.6) % 2
            let rect = g.actor(.speakerMark, x: HallLayout.throneX, lift: HallLayout.lift(at: HallLayout.throneX)
                               + CourtFrames.throneMarkY)
            if g.onScreen(rect) {
                let gold = CourtFrames.throneMarkGold
                actors.append(ActorInstance(sprite: .speakerMark, frame: pulse, rect: rect,
                                            tint: SIMD4<Float>(gold.x, gold.y, gold.z, 1), flipped: false,
                                            isEmissive: true, isLit: true))
            }
        }
        // The lord: seated on the throne during the audience, else walking his hall with his lantern.
        let lord = input.lord
        let night = torch
        let lordX: Double
        let lordLift: Double
        let lordFacing: Int
        if input.court.audience?.place == .throne {
            lordX = HallLayout.throneX
            lordLift = HallLayout.lift(at: lordX)
            lordFacing = -1
            let frame = CourtFrames.lordSeatedFrame(seconds: reduceMotion ? nil : input.court.lordSeated,
                                                    animTime: animTime)
            addActor(lord.seated, frame: frame, x: lordX, lift: lordLift, facing: lordFacing)
            if night >= 0.3 {
                let shade = Float(0.6 + 0.4 * (night - 0.3) / 0.7)
                addActor(lord.seatedGlow, frame: frame, x: lordX, lift: lordLift, facing: lordFacing, shade: shade,
                         emissive: true)
            }
        } else {
            let walker = input.scene.walker
            lordX = walker.x
            lordLift = HallLayout.lift(at: lordX)
            lordFacing = walker.facing
            let frame: Int
            if walker.isWalking {
                let step = Int((walker.x * Double(walker.facing) / EntityFrames.kingStride).rounded(.down))
                frame = ((step % 6) + 6) % 6
            } else {
                frame = 6 + FrameBuilder.idleFrame(time: animTime, frames: 2)
            }
            addActor(lord.body, frame: frame, x: lordX, lift: lordLift, facing: lordFacing)
            if night >= 0.3 {
                let shade = Float(0.6 + 0.4 * (night - 0.3) / 0.7)
                addActor(lord.glow, frame: frame, x: lordX, lift: lordLift, facing: lordFacing, shade: shade,
                         emissive: true)
            }
        }
        light(.lantern, x: lordX + EntityFrames.kingGlass.dx * Double(lordFacing),
              row: HallLayout.floorRow - Int((lordLift + EntityFrames.kingGlass.dy).rounded()), radius: 40,
              intensity: 0.3 + 0.7 * night, seed: 0x4C4F_5244)

        var planes: [PlaneLayer] = []
        for plane in Plane.allCases {
            planes.append(PlaneLayer(offset: offsets[plane.rawValue], sprites: sprites[plane.rawValue]))
        }
        let spriteCount = sprites.reduce(0) { $0 + $1.count }
        let counts = FrameCounts(sprites: spriteCount, actors: actors.count, emissives: emissives.count,
                                 lights: lights.count)
        let lordAnchor = g.actor(lord.body, x: lordX, lift: 0)
        var desc = FrameDesc(scale: framing.targetScale,
                             physicalWidth: pixelScale.physicalWidth,
                             physicalHeight: pixelScale.physicalHeight,
                             targetWidth: g.targetWidth,
                             targetHeight: g.targetHeight,
                             groundRow: groundRow,
                             groundDeviceY: Int(g.groundDeviceY.rounded()),
                             hour: s.hour,
                             phase: DayClock.phase(at: s.hour),
                             cameraX: left,
                             kingX: lordX,
                             kingScreenX: Int(lordAnchor.x + lordAnchor.z / 2),
                             planes: planes,
                             actors: actors,
                             lights: lights,
                             emissives: emissives,
                             fog: [],
                             ambient: ambient,
                             skyTop: ambient.skyTop,
                             skyBottom: ambient.skyBottom,
                             starAlpha: ambient.starAlpha,
                             bankEdge: -10_000,
                             bankAmbientScale: Float(DarknessBank.ambientScale),
                             lightStyle: options.lightStyle,
                             lightBands: FrameBuilder.lightBands,
                             bloom: options.effects.bloom,
                             debugLights: options.debugLights,
                             counts: counts)
        desc.look = options.look
        if abs(zoom - Double(framing.targetScale)) > 1e-6 { desc.zoom = zoom }
        if options.look == .two { desc.interior = interior(ambient, groundRow: groundRow) }
        return desc
    }
}
