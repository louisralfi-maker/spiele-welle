import SwiftUI

/// Something that lives for a few seconds in the scene, spawned by a sim event.
struct SceneEffect: Sendable, Identifiable {
    enum Kind: Sendable {
        /// A dropped stage tumbling away.
        case debris(stage: Int, scale: Double, side: Double)
        /// A released satellite: unfolds and glides onto its ring, or tumbles away dimmed when `ring` is nil.
        case satellite(ring: Int?, side: Double)
        /// A rating pop-up above the rocket, `lift` points higher than the first slot, so it keeps clear of every pop-up
        /// still on screen (`popupLift`).
        case popup(text: String, tint: Color, lift: Double)
    }

    /// A rating pop-up is drawn this long (it fades from 0.9 s), rising at `popupRise` points per second.
    static let popupLife = 1.4
    static let popupRise = 28.0
    /// The vertical distance two pop-ups keep (26 pt capitals, their shadow and the pop-in zoom).
    static let popupGap = 32.0
    /// The highest a new pop-up starts above the first slot.
    static let popupMaxLift = 110.0

    /// Where a new pop-up starts: the lowest lift at least `popupGap` away from every pop-up still on screen (`taken`:
    /// their current lifts, risen ones included). All pop-ups rise at the same speed, so the distance at spawn holds for
    /// their whole life.
    static func popupLift(clearOf taken: [Double]) -> Double {
        let candidates = ([0] + taken.map { $0 + popupGap }).sorted()
        for lift in candidates where lift <= popupMaxLift {
            if taken.allSatisfy({ abs($0 - lift) >= popupGap - 0.001 }) { return lift }
        }
        return popupMaxLift
    }

    /// A delivered satellite pops out sideways, then glides onto its ring line, where the line itself draws it on.
    static let popTime = 0.45
    static let glideTime = 1.1
    static let glideEnd = popTime + glideTime

    let id: Int
    let kind: Kind
    /// Driver clock at spawn.
    let spawn: Double
    let altitude: Double
    let speed: Double
}

/// A copy of everything the scene draws, taken once per frame.
struct SceneState: Sendable {
    var altitude: Double
    var speed: Double
    var phase: FlightPhase
    var clock: Double
    var span: Double
    /// Scale of every stage of the rocket, bottom first (the top stage is 1).
    var stageScales: [Double]
    var stageIndex: Int
    var effects: [SceneEffect]
    var best: Double
    var last: Double?
    var ringDeliveries: [Int]
    var reduceMotion: Bool
    var sinceDrop: Double
    var guidance: Int
    /// Fuel left in the burning stage, 0 … 1, and the gauge zones for this guidance level.
    var fuel: Double
    var zones: (perfect: Double, great: Double, good: Double)
    var cue: GaugeCue
    /// The band the rocket is inside right now (only while satellites are aboard) and what a release would rate there.
    var bandRing: Int?
    var bandRating: ReleaseRating
    /// Where the rocket stalls without more thrust (nil on the pad and after the apex).
    var predictedApex: Double?
    /// The bottom edge of the HUD's top bar in scene points (measured by FlightView): labels keep below it.
    var hudBottom: CGFloat = 132
}

/// Maps altitudes to screen rows. The rocket's reference point, the cargo hatch, sits at 60 % of the screen height; the
/// world scrolls.
struct SceneCamera {
    let size: CGSize
    let rocketY: CGFloat
    let pxPerKm: CGFloat
    let altitude: Double

    init(size: CGSize, altitude: Double, span: Double) {
        self.size = size
        self.rocketY = size.height * 0.6
        self.pxPerKm = size.height / CGFloat(max(1, span))
        self.altitude = altitude
    }

    func y(_ alt: Double) -> CGFloat {
        let delta = CGFloat(alt - altitude)
        return rocketY - delta * pxPerKm
    }

    func altitude(atY y: CGFloat) -> Double {
        altitude + Double((rocketY - y) / pxPerKm)
    }
}

/// The rocket's parts in screen points, relative to its reference point (0, 0): the cargo hatch at the base of the nose,
/// the top of the top stage. That is the point whose altitude counts for a release, and it never moves when lower stages
/// drop, so the stages hang below it and the nose sits above it.
struct RocketLayout {
    /// One rect per stage of the whole rocket, bottom first.
    var stages: [CGRect]
    var nose: CGRect
    var fullHeight: CGFloat
    /// The bottom of stage 0 (where the rocket stands on the pad).
    var baseY: CGFloat

    /// Width and height of a stage of scale `s` before fitting.
    static func rawSize(_ scale: Double) -> CGSize {
        let width = 34.0 * pow(scale, 0.3)
        let height = 30.0 * pow(scale, 0.45)
        return CGSize(width: width, height: height)
    }

    init(scales: [Double], maxHeight: CGFloat) {
        let raw = scales.map(RocketLayout.rawSize)
        let topWidth = raw.last?.width ?? 34
        let noseHeight = topWidth * 1.3
        let stackHeight = raw.reduce(CGFloat(0)) { $0 + $1.height }
        let total = stackHeight + noseHeight
        let fit = min(1, maxHeight / total)
        fullHeight = total * fit
        var rects = Array(repeating: CGRect.zero, count: raw.count)
        var y: CGFloat = 0
        for index in raw.indices.reversed() {
            let w = raw[index].width * fit
            let h = raw[index].height * fit
            rects[index] = CGRect(x: -w / 2, y: y, width: w, height: h)
            y += h
        }
        stages = rects
        baseY = y
        let noseW = topWidth * fit
        let noseH = noseHeight * fit
        nose = CGRect(x: -noseW / 2, y: -noseH, width: noseW, height: noseH)
    }
}

/// Draws the flight: sky by altitude, stars, the curving planet, clouds, rings, apex lines, the rocket with flame and
/// smoke, and the effects. Pure drawing: it reads a SceneState and changes nothing.
enum FlightScene {
    static let bestLabel = String(localized: "Best")
    static let lastLabel = String(localized: "Last")
    static let apexLabel = String(localized: "Apex")
    static let dropLabel = String(localized: "Drop!")

    static func draw(_ context: inout GraphicsContext, size: CGSize, state: SceneState) {
        let camera = SceneCamera(size: size, altitude: state.altitude, span: state.span)
        let layout = RocketLayout(scales: state.stageScales, maxHeight: min(240, size.height * 0.28))
        // The jolt of a stage drop is FlightShake's job (FlightView), whose zoom covers it; the scene itself stays put.
        let ctx = context
        drawSky(ctx, camera: camera)
        drawStars(ctx, camera: camera, state: state)
        drawPlanet(ctx, camera: camera, layout: layout, state: state)
        drawClouds(ctx, camera: camera, state: state)
        drawRings(ctx, camera: camera, state: state)
        drawApexLines(ctx, camera: camera, state: state)
        drawSmoke(ctx, camera: camera, layout: layout, state: state)
        drawEffects(ctx, camera: camera, layout: layout, state: state, popups: false)
        // The ring plates sit above the released satellites gliding onto the lines, so the pay stays readable.
        drawRingLabels(ctx, camera: camera, layout: layout, state: state)
        drawRocket(ctx, camera: camera, layout: layout, state: state)
        drawEffects(ctx, camera: camera, layout: layout, state: state, popups: true)
    }

    // MARK: Sky and space

    static func drawSky(_ ctx: GraphicsContext, camera: SceneCamera) {
        let h = camera.size.height
        var stops: [Gradient.Stop] = []
        let samples = 7
        for index in 0..<samples {
            let t = CGFloat(index) / CGFloat(samples - 1)
            let alt = max(0, camera.altitude(atY: t * h))
            stops.append(Gradient.Stop(color: Palette.sky(at: alt).color, location: t))
        }
        let rect = CGRect(origin: .zero, size: camera.size)
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(stops: stops), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h))
        ctx.fill(Path(rect), with: shading)
        drawPaperGrain(ctx, rect: rect)
    }

    /// The painted poster paper over the sky: a grey tile (mean 50 % grey) in overlay mode, so it adds grain to the cream
    /// sky and to deep space alike without shifting their colour. Fixed to the screen like the paper of a print, so it adds
    /// no motion. Without the file the sky stays plain (the procedural PaperGrain overlay still sits above the scene).
    static func drawPaperGrain(_ ctx: GraphicsContext, rect: CGRect) {
        guard let tile = ArtAsset.image(ArtName.paper, scale: 2) else { return }
        var grain = ctx
        grain.blendMode = .overlay
        grain.opacity = 0.6
        grain.fill(Path(rect), with: .tiledImage(tile))
    }

    static func drawStars(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        let fade = min(1, max(0, (state.altitude - 60) / 120))
        guard fade > 0 else { return }
        let w = camera.size.width
        let h = camera.size.height
        let drift = CGFloat(state.altitude * 0.35)
        for index in 0..<110 {
            let fx = fraction(Double(index) * 0.6180339 + 0.13)
            let fy = fraction(Double(index) * 0.4142135 + 0.71)
            let x = CGFloat(fx) * w
            let rawY = CGFloat(fy) * h + drift * CGFloat(0.4 + fraction(Double(index) * 0.27))
            let y = rawY.truncatingRemainder(dividingBy: h)
            let big = index % 9 == 0
            let r: CGFloat = big ? 1.8 : 1.0
            var twinkle = 1.0
            if !state.reduceMotion {
                twinkle = 0.7 + 0.3 * sin(state.clock * 1.7 + Double(index))
            }
            let alpha = fade * twinkle * (big ? 0.95 : 0.7)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(alpha)))
        }
    }

    /// The ground near the pad, and from higher up the planet whose horizon curves more and more with altitude.
    static func drawPlanet(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) {
        let w = camera.size.width
        let h = camera.size.height
        let groundY = camera.y(0) + layout.baseY
        let lifted = log10(1 + state.altitude / 5) / 2.3
        let rise = CGFloat(min(1, max(0, lifted)))
        let limbY = h * (0.97 - 0.13 * rise)
        // The ground under the pad while it is in view; once it scrolls away, the planet's limb low on the screen.
        let horizonY = min(groundY, limbY)
        guard horizonY < h + 2 else { return }
        let sag = w * (0.004 + 0.46 * rise * rise)
        let radius = (w * w / 4 + sag * sag) / (2 * sag)
        let center = CGPoint(x: w / 2, y: horizonY + radius)
        let disc = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        // Atmosphere glow above the limb.
        let glowAlpha = 0.35 * Double(rise)
        if glowAlpha > 0.01 {
            for ring in 1...4 {
                let grow = CGFloat(ring) * 5
                let halo = disc.insetBy(dx: -grow, dy: -grow)
                ctx.stroke(Path(ellipseIn: halo), with: .color(Palette.skyTeal.opacity(glowAlpha / Double(ring))), lineWidth: 6)
            }
        }
        drawLaunchSite(ctx, groundY: groundY, width: w, height: h, altitude: state.altitude)
        let surface = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Palette.skyTealRGB.mix(Palette.groundRGB, 0.5).color, Palette.groundRGB.color, Palette.navyRGB.mix(Palette.groundRGB, 0.5).color]),
            startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: horizonY + min(radius, h)))
        ctx.fill(Path(ellipseIn: disc), with: surface)
        // From about 6 km up: the painted planet surface (cloud bands, seas, islands), or without the file the cream
        // dashed cloud bands.
        if rise > 0.15, let tile = ArtAsset.image(ArtName.planetSurface, scale: 3) {
            let fade = Double(min(1, (rise - 0.15) * 2))
            drawPlanetSurface(ctx, tile: tile, disc: disc, size: camera.size, horizonY: horizonY, rise: rise, fade: fade,
                              state: state)
        } else if rise > 0.15 {
            var bands = ctx
            bands.clip(to: Path(ellipseIn: disc))
            let bandAlpha = Double(min(1, (rise - 0.15) * 2)) * 0.35
            for index in 0..<4 {
                let offset = CGFloat(index) * 18 + 10
                let arc = disc.insetBy(dx: offset * 1.6, dy: offset)
                bands.stroke(Path(ellipseIn: arc), with: .color(Palette.cream.opacity(bandAlpha)), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [40, 26 + CGFloat(index) * 9]))
            }
        }
        // The pad and its tower while the ground is in view.
        if groundY < h {
            let padWidth = layout.stages.first.map { $0.width * 2.2 } ?? 80
            let pad = CGRect(x: w / 2 - padWidth / 2, y: groundY, width: padWidth, height: 10)
            ctx.fill(Path(roundedRect: pad, cornerRadius: 3), with: .color(Palette.ink.opacity(0.8)))
            let towerX = w / 2 - padWidth / 2 - 18
            let towerTop = groundY - layout.fullHeight * 0.85
            var tower = Path()
            tower.addRect(CGRect(x: towerX, y: towerTop, width: 10, height: groundY - towerTop))
            ctx.stroke(tower, with: .color(Palette.ink.opacity(0.75)), lineWidth: 2)
            var lattice = Path()
            var yy = towerTop
            var flip = false
            while yy + 10 < groundY {
                lattice.move(to: CGPoint(x: flip ? towerX : towerX + 10, y: yy))
                lattice.addLine(to: CGPoint(x: flip ? towerX + 10 : towerX, y: yy + 10))
                yy += 10
                flip.toggle()
            }
            ctx.stroke(lattice, with: .color(Palette.ink.opacity(0.6)), lineWidth: 1.2)
            var arm = Path()
            arm.move(to: CGPoint(x: towerX + 10, y: towerTop + 12))
            arm.addLine(to: CGPoint(x: w / 2 - (layout.stages.last?.width ?? 30) / 2, y: towerTop + 12))
            ctx.stroke(arm, with: .color(Palette.ink.opacity(0.6)), lineWidth: 2)
            ctx.fill(Path(ellipseIn: CGRect(x: towerX + 1, y: towerTop - 8, width: 8, height: 8)), with: .color(Palette.coral))
        }
    }

    /// The painted planet surface on the horizon disc: a seamless tile, squashed as if seen at a grazing angle and finer
    /// the higher the rocket climbs, turning slowly (standing still under Reduce Motion), with a navy veil deepening
    /// downward and a pale haze along the limb, so the disc reads round. The tile stays sharp at any disc radius.
    static func drawPlanetSurface(_ ctx: GraphicsContext, tile: Image, disc: CGRect, size: CGSize, horizonY: CGFloat,
                                  rise: CGFloat, fade: Double, state: SceneState) {
        let w = size.width
        let h = max(horizonY + 1, size.height)
        let shape = Path(ellipseIn: disc)
        let zoom = 1.5 - 0.9 * rise
        let squash = 0.32 + 0.3 * rise
        let drift = state.reduceMotion ? 0 : CGFloat(state.clock * 5)
        var tex = ctx
        tex.clip(to: shape)
        tex.opacity = 0.85 * fade
        tex.translateBy(x: 0, y: horizonY)
        tex.scaleBy(x: zoom, y: zoom * squash)
        let area = CGRect(x: 0, y: -2, width: w / zoom, height: (h - horizonY) / (zoom * squash) + 4)
        tex.fill(Path(area), with: .tiledImage(tile, origin: CGPoint(x: drift, y: 0)))
        var veil = ctx
        veil.clip(to: shape)
        let below = CGRect(x: 0, y: horizonY, width: w, height: h - horizonY)
        veil.fill(Path(below), with: .linearGradient(
            Gradient(colors: [Palette.navy.opacity(0), Palette.navy.opacity(0.5 * fade)]),
            startPoint: CGPoint(x: 0, y: horizonY + 40), endPoint: CGPoint(x: 0, y: horizonY + 260)))
        veil.fill(Path(below), with: .linearGradient(
            Gradient(colors: [Palette.skyTeal.opacity(0.55 * fade), Palette.skyTeal.opacity(0)]),
            startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: horizonY + 26)))
    }

    /// The painted launch site: low mesas, a tiny distant tower and fuel tanks, standing on the ground line behind the pad.
    /// It is fixed to the ground, so it scrolls away with it as the rocket climbs, and it fades out over the first 8 km.
    /// Drawn before the ground disc, which covers its bottom edge. Without the file nothing is drawn.
    static func drawLaunchSite(_ ctx: GraphicsContext, groundY: CGFloat, width: CGFloat, height: CGFloat, altitude: Double) {
        let fade = 1 - altitude / 8
        guard fade > 0, let art = ArtAsset.image(ArtName.launchSite) else { return }
        let artHeight = width / ArtAsset.aspect(ArtName.launchSite)
        let rect = CGRect(x: 0, y: groundY - artHeight + 3, width: width, height: artHeight)
        guard rect.minY < height else { return }
        var layer = ctx
        layer.opacity = 0.92 * fade
        layer.draw(art, in: rect)
    }

    static func drawClouds(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        let w = camera.size.width
        let h = camera.size.height
        let drift = state.reduceMotion ? 0 : CGFloat(state.clock * 4)
        for index in 0..<22 {
            let alt = 3 + 12 * fraction(Double(index) * 0.6180339 + 0.05)
            let y = camera.y(alt)
            let scale = CGFloat(0.7 + 0.6 * fraction(Double(index) * 0.371))
            let cw = 90 * scale
            // Room below for the tall painted tower cloud, whose top stands well above its base line.
            guard y > -60, y < h + 140 else { continue }
            // Wrap off screen on both sides, with room for the wider painted clouds, so none pops in at an edge.
            let margin = cw * 1.3
            let span = w + margin * 2
            let base = CGFloat(fraction(Double(index) * 0.7548777)) * span
            let speed = CGFloat(0.5 + fraction(Double(index) * 0.29))
            let x = (base + drift * speed).truncatingRemainder(dividingBy: span) - margin
            let near = fraction(Double(index) * 0.53) > 0.5
            if let art = ArtAsset.image(ArtName.cloud(index)) {
                drawPaintedCloud(ctx, art: art, index: index, at: CGPoint(x: x, y: y), width: cw, near: near)
                continue
            }
            let tint = near ? Palette.paper : Palette.cream
            let alpha = near ? 0.92 : 0.7
            drawCloud(ctx, at: CGPoint(x: x, y: y), width: cw, color: tint.opacity(alpha))
        }
    }

    /// Width of each painted cloud against the procedural one it replaces (stratus, two-puff, lenticular, tower, wide
    /// cumulus, three puffs), so the long thin shapes are drawn longer and the small puff smaller.
    static let paintedCloudWidths: [CGFloat] = [1.3, 0.7, 1.15, 0.85, 1.15, 1.0]

    /// A painted poster cloud in the slot of a procedural one, centred on it, its flat base on the same line (`point.y`
    /// plus the procedural body height), far clouds paler. Six silhouettes for 22 clouds: every second round of six is
    /// mirrored and each cloud gets its own height (85 to 115 %), so no two repeats look stamped.
    static func drawPaintedCloud(_ ctx: GraphicsContext, art: Image, index: Int, at point: CGPoint, width: CGFloat,
                                 near: Bool) {
        let name = ArtName.cloud(index)
        let shape = paintedCloudWidths[index % paintedCloudWidths.count]
        let paintedWidth = width * 1.25 * shape
        let stretch = CGFloat(0.85 + 0.3 * fraction(Double(index) * 0.43))
        let paintedHeight = paintedWidth / ArtAsset.aspect(name) * stretch
        let base = point.y + width * 0.32
        let midX = point.x + width * 0.5
        let rect = CGRect(x: midX - paintedWidth / 2, y: base - paintedHeight, width: paintedWidth, height: paintedHeight)
        var layer = ctx
        layer.opacity = near ? 1 : 0.72
        if (index / paintedCloudWidths.count) % 2 == 1 {
            layer.translateBy(x: midX, y: 0)
            layer.scaleBy(x: -1, y: 1)
            layer.translateBy(x: -midX, y: 0)
        }
        layer.draw(art, in: rect)
    }

    static func drawCloud(_ ctx: GraphicsContext, at point: CGPoint, width: CGFloat, color: Color) {
        let h = width * 0.32
        var path = Path()
        path.addRoundedRect(in: CGRect(x: point.x, y: point.y, width: width, height: h), cornerSize: CGSize(width: h / 2, height: h / 2))
        path.addEllipse(in: CGRect(x: point.x + width * 0.14, y: point.y - h * 0.55, width: width * 0.38, height: h * 1.2))
        path.addEllipse(in: CGRect(x: point.x + width * 0.42, y: point.y - h * 0.85, width: width * 0.36, height: h * 1.4))
        ctx.fill(path, with: .color(color))
    }

    // MARK: Rings

    static func drawRings(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        let w = camera.size.width
        let h = camera.size.height
        let shares = Ratings.releaseShares(guidance: state.guidance)
        for ring in 0..<Rings.count {
            let center = Rings.altitudes[ring]
            let half = Rings.halfWidth(ring, speed: state.speed)
            let yTop = camera.y(center + half)
            let yBottom = camera.y(center - half)
            guard yBottom > -40, yTop < h + 40 else { continue }
            let y = camera.y(center)
            let delivered = ring < state.ringDeliveries.count ? max(0, state.ringDeliveries[ring]) : 0
            let complete = delivered >= Economy.ringSlots
            let tint = complete ? Palette.gold : Palette.mustard
            let live = state.bandRing == ring
            let perfect = live && state.bandRating == .perfect
            var layer = ctx
            layer.opacity = outOfReach(ring, state: state) ? 0.35 : 1
            let peak = live ? 0.38 : 0.16
            let band = CGRect(x: 0, y: yTop, width: w, height: max(2, yBottom - yTop))
            layer.fill(Path(band), with: .linearGradient(
                Gradient(colors: [tint.opacity(0), tint.opacity(peak), tint.opacity(0)]),
                startPoint: CGPoint(x: 0, y: band.minY), endPoint: CGPoint(x: 0, y: band.maxY)))
            drawPerfectStrip(layer, camera: camera, center: center, half: half * shares.perfect, tint: tint, live: live)
            drawCenterLine(layer, y: y, width: w, tint: tint, live: live, perfect: perfect, state: state)
            // Satellites already delivered here drift along the line.
            let count = min(Economy.ringSlots, delivered)
            for index in 0..<max(0, count) {
                let seed = fraction(Double(ring) * 0.37 + Double(index) * 0.21)
                let speed = 0.012 + 0.006 * Double(index)
                let moving = state.reduceMotion ? 0 : state.clock * speed
                let x = CGFloat(fraction(seed + moving)) * w
                drawSatellite(layer, at: CGPoint(x: x, y: y), size: 18, variant: ring)
            }
        }
    }

    /// The label plates of the rings in view (ring number, altitude, pay), in their own pass after the effects.
    static func drawRingLabels(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) {
        let h = camera.size.height
        let popups = popupFrames(ctx, camera: camera, layout: layout, state: state)
        for ring in 0..<Rings.count {
            let y = camera.y(Rings.altitudes[ring])
            guard y > -10, y < h + 50 else { continue }
            let delivered = ring < state.ringDeliveries.count ? max(0, state.ringDeliveries[ring]) : 0
            let tint = delivered >= Economy.ringSlots ? Palette.gold : Palette.mustard
            var layer = ctx
            layer.opacity = outOfReach(ring, state: state) ? 0.35 : 1
            drawRingLabel(layer, ring: ring, y: y, tint: tint, live: state.bandRing == ring, hudBottom: state.hudBottom,
                          popups: popups)
        }
    }

    /// While the rocket coasts, the predicted apex is exact: a ring whose band starts above it cannot be reached.
    static func outOfReach(_ ring: Int, state: SceneState) -> Bool {
        guard state.phase == .coasting, let apex = state.predictedApex else { return false }
        return Rings.altitudes[ring] - Rings.baseHalfWidth(ring) > apex
    }

    /// The Perfect part of the band: a brighter strip with thin paper edges, as wide as the real Perfect window.
    static func drawPerfectStrip(_ ctx: GraphicsContext, camera: SceneCamera, center: Double, half: Double, tint: Color, live: Bool) {
        let width = camera.size.width
        let top = camera.y(center + half)
        let bottom = camera.y(center - half)
        let strip = CGRect(x: 0, y: top, width: width, height: max(1, bottom - top))
        ctx.fill(Path(strip), with: .color(tint.opacity(live ? 0.34 : 0.22)))
        var edges = Path()
        edges.move(to: CGPoint(x: 0, y: strip.minY))
        edges.addLine(to: CGPoint(x: width, y: strip.minY))
        edges.move(to: CGPoint(x: 0, y: strip.maxY))
        edges.addLine(to: CGPoint(x: width, y: strip.maxY))
        ctx.stroke(edges, with: .color(Palette.paper.opacity(live ? 0.75 : 0.4)), lineWidth: 1)
    }

    /// The centre line: brighter while the rocket is inside the band, a wide glow while a release would be Perfect
    /// (pulsing, or steady with Reduce Motion).
    static func drawCenterLine(_ ctx: GraphicsContext, y: CGFloat, width: CGFloat, tint: Color, live: Bool, perfect: Bool,
                               state: SceneState) {
        var line = Path()
        line.move(to: CGPoint(x: 0, y: y))
        line.addLine(to: CGPoint(x: width, y: y))
        if perfect {
            let pulse = state.reduceMotion ? 1.0 : 0.7 + 0.3 * sin(state.clock * 30)
            ctx.stroke(line, with: .color(tint.opacity(0.45 * pulse)), lineWidth: 20)
            ctx.stroke(line, with: .color(tint), lineWidth: 6)
            ctx.stroke(line, with: .color(Palette.paper), lineWidth: 2.5)
        } else if live {
            ctx.stroke(line, with: .color(tint.opacity(0.4)), lineWidth: 12)
            ctx.stroke(line, with: .color(tint), lineWidth: 4)
            ctx.stroke(line, with: .color(Palette.paper.opacity(0.95)), lineWidth: 1.5)
        } else {
            ctx.stroke(line, with: .color(tint.opacity(0.25)), lineWidth: 9)
            ctx.stroke(line, with: .color(tint.opacity(0.5)), lineWidth: 4)
            ctx.stroke(line, with: .color(Palette.paper.opacity(0.95)), lineWidth: 1.5)
        }
    }

    /// A ring's plate: number and coin, altitude and pay. It sits above the centre line, or below it while above would put
    /// it under the HUD; it is as wide as its title needs (French "Anneau 12"); it dims while a rating pop-up covers it.
    static func drawRingLabel(_ ctx: GraphicsContext, ring: Int, y: CGFloat, tint: Color, live: Bool, hudBottom: CGFloat,
                              popups: [CGRect]) {
        let km = Int(Rings.altitudes[ring])
        let titleColor = live ? Palette.ink : tint
        let detailColor = live ? Palette.ink : Palette.paper.opacity(0.9)
        let payColor = live ? Palette.ink : Palette.mustard
        let title = Text("Ring \(ring + 1)").font(.rounded(14, .heavy)).foregroundStyle(titleColor)
        let detail = Text("\(km) km").font(.rounded(13, .bold)).foregroundStyle(detailColor)
        let pay = Text(verbatim: "\(Rings.basePay(ring))").font(.rounded(13, .heavy).monospacedDigit()).foregroundStyle(payColor)
        let resolvedTitle = ctx.resolve(title)
        let titleWidth = resolvedTitle.measure(in: CGSize(width: 240, height: 30)).width
        let above = y - 42
        let top = above < hudBottom ? y + 6 : above
        let plate = CGRect(x: 62, y: top, width: max(98, titleWidth + 8 + 22), height: 36)
        var layer = ctx
        if popups.contains(where: { $0.insetBy(dx: -4, dy: -4).intersects(plate) }) {
            layer.opacity *= 0.3
        }
        let plateFill = live ? tint : Palette.night.opacity(0.55)
        layer.fill(Path(roundedRect: plate, cornerRadius: 9), with: .color(plateFill))
        layer.draw(resolvedTitle, at: CGPoint(x: plate.minX + 8, y: plate.minY + 10), anchor: .leading)
        layer.draw(detail, at: CGPoint(x: plate.minX + 8, y: plate.minY + 26), anchor: .leading)
        layer.draw(pay, at: CGPoint(x: plate.maxX - 8, y: plate.minY + 26), anchor: .trailing)
        CoinShape.draw(in: layer, center: CGPoint(x: plate.maxX - 13, y: plate.minY + 10), radius: 5.5)
    }

    static func drawApexLines(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        if state.best > 1 {
            drawApexLine(ctx, camera: camera, altitude: state.best, label: bestLabel, color: Palette.coral)
        }
        if let last = state.last, last > 1, abs(last - state.best) >= 0.5 {
            drawApexLine(ctx, camera: camera, altitude: last, label: lastLabel, color: Palette.paper)
        }
        if let apex = state.predictedApex, apex > 1 {
            drawPredictedApex(ctx, camera: camera, apex: apex, exact: state.phase == .coasting, hudBottom: state.hudBottom)
        }
    }

    static func drawApexLine(_ ctx: GraphicsContext, camera: SceneCamera, altitude: Double, label: String, color: Color) {
        let y = camera.y(altitude)
        guard y > -10, y < camera.size.height + 10 else { return }
        let w = camera.size.width
        var line = Path()
        line.move(to: CGPoint(x: 0, y: y))
        line.addLine(to: CGPoint(x: w, y: y))
        ctx.stroke(line, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
        let text = Text(verbatim: "\(label) \(Int(altitude.rounded())) km").font(.rounded(13, .heavy)).foregroundStyle(color)
        ctx.draw(text, at: CGPoint(x: w - 10, y: y - 10), anchor: .trailing)
    }

    /// Where the rocket stalls: rises live while a stage burns (dimmer), exact while it coasts. The line stays at the
    /// apex; its plate never goes up under the HUD.
    static func drawPredictedApex(_ ctx: GraphicsContext, camera: SceneCamera, apex: Double, exact: Bool, hudBottom: CGFloat) {
        let y = camera.y(apex)
        guard y > -10, y < camera.size.height + 10 else { return }
        let w = camera.size.width
        var line = Path()
        line.move(to: CGPoint(x: 0, y: y))
        line.addLine(to: CGPoint(x: w, y: y))
        let alpha = exact ? 0.95 : 0.55
        ctx.stroke(line, with: .color(Palette.coral.opacity(alpha)), style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
        let label = "\(apexLabel) ≈ \(Int(apex.rounded())) km"
        let text = Text(verbatim: label).font(.rounded(13, .heavy)).foregroundStyle(Palette.paper)
        let resolved = ctx.resolve(text)
        let size = resolved.measure(in: CGSize(width: 260, height: 40))
        let plate = CGRect(x: w - 14 - size.width, y: max(y + 4, hudBottom + 4), width: size.width + 8,
                           height: size.height + 4)
        ctx.fill(Path(roundedRect: plate, cornerRadius: plate.height / 2), with: .color(Palette.coral.opacity(alpha)))
        ctx.draw(resolved, at: CGPoint(x: plate.midX, y: plate.midY), anchor: .center)
    }

    // MARK: Rocket

    static func drawRocket(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) {
        guard state.stageIndex >= 0, state.stageIndex < layout.stages.count else { return }
        var rocket = ctx
        rocket.translateBy(x: camera.size.width / 2, y: camera.rocketY)
        let attached = Array(state.stageIndex..<layout.stages.count)
        let bottomIndex = state.stageIndex
        let bottom = layout.stages[bottomIndex]
        let dropNow = state.cue == .perfect || state.cue == .grace
        // In the drop window the bottom stage's band flashes mustard (steady with Reduce Motion).
        let flash = dropNow && (state.reduceMotion || sin(state.clock * 18) > -0.3)
        if state.phase == .burning {
            drawFlame(rocket, below: bottom, clock: state.clock, calm: state.reduceMotion)
        }
        drawNozzle(rocket, under: bottom)
        drawFins(rocket, on: bottom)
        for index in attached.reversed() {
            let isTop = index == layout.stages.count - 1
            let lit = flash && index == bottomIndex
            drawStage(rocket, rect: layout.stages[index], index: index, isTop: isTop, dim: false, flash: lit)
        }
        drawNose(rocket, rect: layout.nose)
        drawHatch(rocket, layout: layout, state: state)
        let showBar = state.cue != .last && (state.phase == .burning || state.phase == .spent)
        if showBar {
            drawFuelBar(rocket, beside: bottom, state: state)
        }
        if dropNow {
            drawDropCue(rocket, beside: bottom, state: state)
        }
    }

    /// The cargo hatch at the base of the nose: the point that must meet a ring's centre line. Mustard ticks stick out on
    /// both sides; they grow while the rocket is inside a band and turn gold while a release would be Perfect.
    static func drawHatch(_ ctx: GraphicsContext, layout: RocketLayout, state: SceneState) {
        guard let top = layout.stages.last else { return }
        let live = state.bandRing != nil
        let perfect = live && state.bandRating == .perfect
        let color = perfect ? Palette.gold : Palette.mustard
        let reach: CGFloat = perfect ? 18 : (live ? 13 : 8)
        var seam = Path()
        seam.move(to: CGPoint(x: top.minX + 1, y: 0))
        seam.addLine(to: CGPoint(x: top.maxX - 1, y: 0))
        ctx.stroke(seam, with: .color(color), lineWidth: 2.5)
        var ticks = Path()
        ticks.move(to: CGPoint(x: top.minX - reach, y: 0))
        ticks.addLine(to: CGPoint(x: top.minX - 2, y: 0))
        ticks.move(to: CGPoint(x: top.maxX + 2, y: 0))
        ticks.addLine(to: CGPoint(x: top.maxX + reach, y: 0))
        ctx.stroke(ticks, with: .color(Palette.ink.opacity(0.55)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        ctx.stroke(ticks, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    /// A slim tank beside the bottom stage with the same zones as the big gauge, so the drop cue sits next to the ring
    /// lines the eyes follow.
    static func drawFuelBar(_ ctx: GraphicsContext, beside stage: CGRect, state: SceneState) {
        let height = min(60, max(36, stage.height * 1.4))
        let x = stage.maxX + stage.width * 0.42 + 8
        let track = CGRect(x: x, y: stage.maxY - height, width: 7, height: height)
        let shape = Path(roundedRect: track, cornerRadius: 3.5)
        ctx.fill(shape, with: .color(Palette.night.opacity(0.55)))
        let fuel = CGFloat(min(1, max(0, state.fuel)))
        let level = track.height * fuel
        let dropNow = state.cue == .perfect || state.cue == .grace
        let fill = dropNow ? Palette.mustard : Palette.fuel
        var inner = ctx
        inner.clip(to: shape)
        inner.fill(Path(CGRect(x: track.minX, y: track.maxY - level, width: track.width, height: level)), with: .color(fill))
        let marks: [(Double, Color)] = [
            (state.zones.good, Palette.paper),
            (state.zones.great, Palette.skyTeal),
            (state.zones.perfect, Palette.mustard),
        ]
        for (top, color) in marks {
            let y = track.maxY - track.height * CGFloat(top)
            var tick = Path()
            tick.move(to: CGPoint(x: track.maxX, y: y))
            tick.addLine(to: CGPoint(x: track.maxX + 4, y: y))
            ctx.stroke(tick, with: .color(color), lineWidth: 2)
        }
        let outline = state.cue == .late ? Palette.coral : (dropNow ? Palette.mustard : Palette.paper.opacity(0.8))
        ctx.stroke(shape, with: .color(outline), lineWidth: 1.5)
    }

    /// "Drop!" next to the rocket while a drop is Perfect: mustard, alternating with coral once the stage is burnt out.
    static func drawDropCue(_ ctx: GraphicsContext, beside stage: CGRect, state: SceneState) {
        let pop = state.reduceMotion ? 1.0 : 1.0 + 0.08 * sin(state.clock * 16)
        let blinkCoral = state.cue == .grace && !state.reduceMotion && sin(state.clock * 14) > 0
        let fill = blinkCoral ? Palette.coral : Palette.mustard
        let text = Text(verbatim: dropLabel).font(.rounded(15, .heavy)).foregroundStyle(Palette.ink)
        let barHeight = min(60, max(36, stage.height * 1.4))
        let tagX = stage.maxX + stage.width * 0.42 + 26
        var tag = ctx
        tag.translateBy(x: tagX, y: stage.maxY - barHeight / 2)
        tag.scaleBy(x: CGFloat(pop), y: CGFloat(pop))
        let resolved = tag.resolve(text)
        let size = resolved.measure(in: CGSize(width: 200, height: 40))
        let plate = CGRect(x: 0, y: -size.height / 2 - 4, width: size.width + 16, height: size.height + 8)
        let shape = Path(roundedRect: plate, cornerRadius: plate.height / 2)
        tag.fill(shape, with: .color(fill))
        tag.stroke(shape, with: .color(Palette.ink.opacity(0.6)), lineWidth: 1.5)
        tag.draw(resolved, at: CGPoint(x: plate.midX, y: plate.midY), anchor: .center)
    }

    static func bodyShading(_ rect: CGRect, dim: Bool) -> GraphicsContext.Shading {
        let edge = Palette.creamRGB.mix(Palette.inkRGB, dim ? 0.35 : 0.14).color
        let mid = dim ? Palette.creamRGB.mix(Palette.inkRGB, 0.2).color : Palette.paper
        return .linearGradient(Gradient(colors: [edge, mid, mid, edge]),
                               startPoint: CGPoint(x: rect.minX, y: 0), endPoint: CGPoint(x: rect.maxX, y: 0))
    }

    static func drawStage(_ ctx: GraphicsContext, rect: CGRect, index: Int, isTop: Bool, dim: Bool, flash: Bool = false) {
        let corner = min(7, rect.width * 0.18)
        let body = Path(roundedRect: rect, cornerRadius: corner)
        ctx.fill(body, with: bodyShading(rect, dim: dim))
        var banded = ctx
        banded.clip(to: body)
        let stripe = index % 2 == 0 ? Palette.coral : Palette.deepTeal
        let bandColor = flash ? Palette.mustard : stripe
        let bandHeight = max(3, rect.height * (flash ? 0.3 : 0.16))
        let band = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.22, width: rect.width, height: bandHeight)
        banded.fill(Path(band), with: .color(bandColor.opacity(dim ? 0.5 : 1)))
        let rivetY = rect.maxY - max(3, rect.height * 0.12)
        var rivets = Path()
        rivets.move(to: CGPoint(x: rect.minX, y: rivetY))
        rivets.addLine(to: CGPoint(x: rect.maxX, y: rivetY))
        banded.stroke(rivets, with: .color(Palette.ink.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        if isTop {
            let r = rect.width * 0.13
            for dx in [-0.22, 0.22] {
                let c = CGPoint(x: rect.midX + rect.width * CGFloat(dx), y: rect.minY + rect.height * 0.66)
                drawPorthole(ctx, center: c, radius: r)
            }
        }
        if flash {
            ctx.stroke(body, with: .color(Palette.mustard.opacity(0.7)), lineWidth: 5)
        }
        ctx.stroke(body, with: .color(Palette.ink.opacity(0.7)), lineWidth: 1.6)
    }

    static func drawPorthole(_ ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: outer), with: .color(Palette.ink.opacity(0.75)))
        let glass = outer.insetBy(dx: radius * 0.28, dy: radius * 0.28)
        ctx.fill(Path(ellipseIn: glass), with: .linearGradient(
            Gradient(colors: [Palette.skyTeal, Palette.navy]),
            startPoint: CGPoint(x: glass.minX, y: glass.minY), endPoint: CGPoint(x: glass.maxX, y: glass.maxY)))
        let shine = CGRect(x: glass.minX + glass.width * 0.2, y: glass.minY + glass.height * 0.15, width: glass.width * 0.3, height: glass.height * 0.25)
        ctx.fill(Path(ellipseIn: shine), with: .color(Palette.paper.opacity(0.8)))
    }

    static func drawNose(_ ctx: GraphicsContext, rect: CGRect) {
        var nose = Path()
        nose.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        nose.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX - rect.width * 0.05, y: rect.minY + rect.height * 0.45),
                      control2: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY))
        nose.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                      control1: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY),
                      control2: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.minY + rect.height * 0.45))
        nose.closeSubpath()
        ctx.fill(nose, with: bodyShading(rect, dim: false))
        var tip = ctx
        tip.clip(to: nose)
        tip.fill(Path(CGRect(x: rect.minX - 4, y: rect.minY - 2, width: rect.width + 8, height: rect.height * 0.3)), with: .color(Palette.coral))
        let r = rect.width * 0.22
        drawPorthole(ctx, center: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.62), radius: r)
        ctx.stroke(nose, with: .color(Palette.ink.opacity(0.7)), lineWidth: 1.6)
    }

    static func drawFins(_ ctx: GraphicsContext, on rect: CGRect) {
        let reach = rect.width * 0.42
        let drop = rect.height * 0.22
        for side in [-1.0, 1.0] {
            let s = CGFloat(side)
            let edgeX = side < 0 ? rect.minX : rect.maxX
            var fin = Path()
            fin.move(to: CGPoint(x: edgeX, y: rect.minY + rect.height * 0.35))
            fin.addQuadCurve(to: CGPoint(x: edgeX + s * reach, y: rect.maxY + drop),
                             control: CGPoint(x: edgeX + s * reach * 0.95, y: rect.minY + rect.height * 0.55))
            fin.addLine(to: CGPoint(x: edgeX + s * reach * 0.55, y: rect.maxY + drop * 0.6))
            fin.addLine(to: CGPoint(x: edgeX, y: rect.maxY - rect.height * 0.05))
            fin.closeSubpath()
            ctx.fill(fin, with: .color(Palette.coral))
            ctx.stroke(fin, with: .color(Palette.ink.opacity(0.7)), lineWidth: 1.4)
        }
    }

    static func drawNozzle(_ ctx: GraphicsContext, under rect: CGRect) {
        let top = rect.width * 0.36
        let bottom = rect.width * 0.5
        let h = max(5, rect.width * 0.16)
        var bell = Path()
        bell.move(to: CGPoint(x: rect.midX - top / 2, y: rect.maxY))
        bell.addLine(to: CGPoint(x: rect.midX + top / 2, y: rect.maxY))
        bell.addLine(to: CGPoint(x: rect.midX + bottom / 2, y: rect.maxY + h))
        bell.addLine(to: CGPoint(x: rect.midX - bottom / 2, y: rect.maxY + h))
        bell.closeSubpath()
        ctx.fill(bell, with: .color(Palette.ink.opacity(0.85)))
    }

    static func drawFlame(_ ctx: GraphicsContext, below rect: CGRect, clock: Double, calm: Bool) {
        let flicker = calm ? 0.5 : 0.5 + 0.5 * sin(clock * 37) * cos(clock * 23)
        let nozzleY = rect.maxY + max(5, rect.width * 0.16)
        let width = rect.width * 0.5
        let length = rect.width * CGFloat(1.5 + 0.45 * flicker)
        let glowRect = CGRect(x: rect.midX - width * 1.6, y: nozzleY - width * 0.4, width: width * 3.2, height: length * 1.2)
        ctx.fill(Path(ellipseIn: glowRect), with: .radialGradient(
            Gradient(colors: [Palette.mustard.opacity(0.45), Palette.mustard.opacity(0)]),
            center: CGPoint(x: rect.midX, y: nozzleY + length * 0.25), startRadius: 0, endRadius: length * 0.7))
        let layers: [(CGFloat, Color)] = [(1.0, Palette.coral), (0.72, Palette.mustard), (0.42, Palette.paper)]
        for (k, color) in layers {
            ctx.fill(flamePath(x: rect.midX, top: nozzleY, width: width * k, length: length * k), with: .color(color))
        }
    }

    static func flamePath(x: CGFloat, top: CGFloat, width: CGFloat, length: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x - width / 2, y: top))
        path.addCurve(to: CGPoint(x: x, y: top + length),
                      control1: CGPoint(x: x - width * 0.6, y: top + length * 0.35),
                      control2: CGPoint(x: x - width * 0.15, y: top + length * 0.8))
        path.addCurve(to: CGPoint(x: x + width / 2, y: top),
                      control1: CGPoint(x: x + width * 0.15, y: top + length * 0.8),
                      control2: CGPoint(x: x + width * 0.6, y: top + length * 0.35))
        path.closeSubpath()
        return path
    }

    static func drawSmoke(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) {
        guard state.phase == .burning || state.phase == .spent else { return }
        let thin = 1 - state.altitude / 30
        guard thin > 0, let bottom = layout.stages[safe: state.stageIndex] else { return }
        let cx = camera.size.width / 2
        let startY = camera.rocketY + bottom.maxY + 8
        let period = 0.07
        let phase = state.clock.truncatingRemainder(dividingBy: period)
        let emitted = floor(state.clock / period)
        let speedPx = CGFloat(max(0, state.speed)) * camera.pxPerKm
        // While the ground is in view the smoke stays above it: puffs that reach it billow sideways along the pad.
        let groundY = camera.y(0) + layout.baseY
        var smoke = ctx
        if groundY < camera.size.height {
            smoke.clip(to: Path(CGRect(x: 0, y: 0, width: camera.size.width, height: max(0, groundY))))
        }
        for j in 0..<16 {
            let age = phase + Double(j) * period
            let id = emitted - Double(j)
            let wobble = CGFloat(sin(id * 1.7)) * CGFloat(6 + age * 26)
            let fall = speedPx * CGFloat(age) + CGFloat(age * 30)
            let r = CGFloat(7 + age * 24)
            let alpha = 0.5 * thin * max(0, 1 - age / 1.1)
            guard alpha > 0.01 else { continue }
            var x = cx + wobble
            var y = startY + fall
            let rest = groundY - r * 0.5
            if y > rest {
                let side: CGFloat = sin(id * 1.7) >= 0 ? 1 : -1
                x += side * (y - rest) * 0.9
                y = rest
            }
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            smoke.fill(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(alpha)))
        }
    }

    // MARK: Effects

    static func drawEffects(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState, popups: Bool) {
        let cx = camera.size.width / 2
        for effect in state.effects {
            let age = state.clock - effect.spawn
            guard age >= 0 else { continue }
            switch effect.kind {
            case .debris(let stage, _, let side):
                guard !popups, age < 5, let rect = layout.stages[safe: stage] else { continue }
                drawDebris(ctx, camera: camera, rect: rect, stage: stage, side: side, age: age, effect: effect, state: state)
            case .satellite(let ring, let side):
                guard !popups else { continue }
                drawSatelliteEffect(ctx, camera: camera, effect: effect, ring: ring, side: side, age: age, state: state)
            case .popup(let text, let tint, let lift):
                guard popups, age < SceneEffect.popupLife else { continue }
                let y = popupY(camera: camera, layout: layout, age: age, lift: lift)
                let pop = popupZoom(age: age, reduceMotion: state.reduceMotion)
                let alpha = age < 0.9 ? 1 : max(0, 1 - (age - 0.9) / 0.5)
                var label = ctx
                label.opacity = alpha
                label.translateBy(x: cx, y: y)
                label.scaleBy(x: CGFloat(pop), y: CGFloat(pop))
                let shadow = Text(verbatim: text).font(.rounded(26, .black)).foregroundStyle(Palette.ink.opacity(0.55))
                let main = Text(verbatim: text).font(.rounded(26, .black)).foregroundStyle(tint)
                label.draw(shadow, at: CGPoint(x: 0, y: 2), anchor: .center)
                label.draw(main, at: .zero, anchor: .center)
            }
        }
    }

    /// The centre row of a pop-up `age` seconds old: above the nose, risen, lifted clear of the others.
    static func popupY(camera: SceneCamera, layout: RocketLayout, age: Double, lift: Double) -> CGFloat {
        let rise = CGFloat(age * SceneEffect.popupRise)
        return camera.rocketY + layout.nose.minY - 26 - rise - CGFloat(lift)
    }

    /// Pop-ups grow in from 1.35× over 0.15 s (not under Reduce Motion).
    static func popupZoom(age: Double, reduceMotion: Bool) -> Double {
        reduceMotion ? 1 : 1 + 0.35 * max(0, 1 - age / 0.15)
    }

    /// Where the pop-ups on screen are, so a ring plate under one can step back.
    static func popupFrames(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) -> [CGRect] {
        var frames: [CGRect] = []
        for effect in state.effects {
            let age = state.clock - effect.spawn
            guard age >= 0, age < SceneEffect.popupLife, case .popup(let text, _, let lift) = effect.kind else { continue }
            let resolved = ctx.resolve(Text(verbatim: text).font(.rounded(26, .black)))
            let size = resolved.measure(in: CGSize(width: camera.size.width, height: 80))
            let zoom = CGFloat(popupZoom(age: age, reduceMotion: state.reduceMotion))
            let width = size.width * zoom
            let height = size.height * zoom
            let y = popupY(camera: camera, layout: layout, age: age, lift: lift)
            frames.append(CGRect(x: camera.size.width / 2 - width / 2, y: y - height / 2, width: width, height: height))
        }
        return frames
    }

    /// A dropped stage: drawn like the stage it was (stripe, nozzle, fins on the bottom stage), it falls away and
    /// tumbles (no tumbling with Reduce Motion), with a puff of smoke where it separated.
    static func drawDebris(_ ctx: GraphicsContext, camera: SceneCamera, rect: CGRect, stage: Int, side: Double, age: Double,
                           effect: SceneEffect, state: SceneState) {
        let cx = camera.size.width / 2
        let seamY = camera.y(effect.altitude) + rect.minY
        if age < 0.8 {
            drawPuff(ctx, at: CGPoint(x: cx, y: seamY), age: age)
        }
        let fallKm = effect.altitude + effect.speed * age - 0.5 * FlightSim.gravity * age * age
        let shift = CGFloat(state.altitude - fallKm) * camera.pxPerKm
        let y = camera.rocketY + rect.midY + shift
        guard y < camera.size.height + 200 else { return }
        let x = cx + CGFloat(side) * CGFloat(12 + age * 30)
        var piece = ctx
        piece.translateBy(x: x, y: y)
        if !state.reduceMotion {
            piece.rotate(by: .radians(side * age * 1.3))
        }
        piece.opacity = max(0, 1 - age / 5)
        let local = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
        drawNozzle(piece, under: local)
        if stage == 0 {
            drawFins(piece, on: local)
        }
        drawStage(piece, rect: local, index: stage, isTop: false, dim: false)
    }

    /// A short ring of smoke puffs that spreads and fades.
    static func drawPuff(_ ctx: GraphicsContext, at point: CGPoint, age: Double) {
        let t = age / 0.8
        let alpha = 0.75 * (1 - t)
        let dist = CGFloat(6 + 26 * t)
        let r = CGFloat(5 + 12 * t)
        for index in 0..<6 {
            let angle = Double(index) / 6 * 2 * Double.pi + 0.4
            let dx = CGFloat(cos(angle)) * dist * 1.4
            let dy = CGFloat(sin(angle)) * dist * 0.6
            let rect = CGRect(x: point.x + dx - r, y: point.y + dy - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(alpha)))
        }
    }

    static func drawSatelliteEffect(_ ctx: GraphicsContext, camera: SceneCamera, effect: SceneEffect,
                                    ring: Int?, side: Double, age: Double, state: SceneState) {
        let cx = camera.size.width / 2
        let s = CGFloat(side)
        let popTime = SceneEffect.popTime
        // The satellite leaves at the hatch, the rocket's reference point, at the altitude it was released.
        let startY = camera.y(effect.altitude)
        if age <= popTime {
            let t = age / popTime
            let eased = CGFloat(1 - pow(1 - t, 3))
            let x = cx + s * (16 + 70 * eased)
            let y = startY - 14 * CGFloat(sin(t * Double.pi))
            drawSatellite(ctx, at: CGPoint(x: x, y: y), size: 26, variant: ring ?? effect.id, unfold: t)
            return
        }
        let popX = cx + s * 86
        if let ring {
            let glide = min(1, (age - popTime) / SceneEffect.glideTime)
            let eased = 1 - pow(1 - glide, 2)
            let target = Rings.altitudes[ring]
            let alt = effect.altitude + (target - effect.altitude) * eased
            let x = popX + s * 30 * CGFloat(eased)
            let y = camera.y(alt)
            guard y > -30, y < camera.size.height + 30 else { return }
            drawSatellite(ctx, at: CGPoint(x: x, y: y), size: 26 - 8 * CGFloat(eased), variant: ring)
        } else {
            let t = age - popTime
            guard t < 3 else { return }
            let x = popX + s * CGFloat(t * 40)
            let y = startY + CGFloat(t * t * 90)
            var dimmed = ctx
            dimmed.opacity = max(0, 1 - t / 3)
            let angle = state.reduceMotion ? 0 : t * 4 * side
            drawSatellite(dimmed, at: CGPoint(x: x, y: y), size: 22, variant: effect.id, dim: true, angle: angle)
        }
    }

    /// A satellite: the painted one when its file is there, else the procedural SatelliteShape. `center` is the body's
    /// centre and `size` the procedural size (the painted one is drawn as wide as the procedural one with open panels,
    /// 1.36 × size). While it unfolds, the painted panels open by widening the picture from 35 % to full width.
    static func drawSatellite(_ ctx: GraphicsContext, at center: CGPoint, size: CGFloat, variant: Int, unfold: Double = 1,
                              dim: Bool = false, angle: Double = 0) {
        let name = ArtName.satellite(variant)
        guard let art = ArtAsset.image(name) else {
            SatelliteShape.draw(in: ctx, at: center, size: size, unfold: unfold, dim: dim, angle: angle)
            return
        }
        let width = size * 1.36
        let height = width / ArtAsset.aspect(name)
        let open = CGFloat(min(1, max(0, unfold)))
        var piece = ctx
        piece.translateBy(x: center.x, y: center.y)
        piece.rotate(by: .radians(angle))
        piece.scaleBy(x: 0.35 + 0.65 * open, y: 1)
        if dim { piece.opacity = 0.45 }
        // The antenna takes the top of the picture: the body's centre sits at about 60 % of its height.
        let rect = CGRect(x: -width / 2, y: -height * 0.6, width: width, height: height)
        piece.draw(art, in: rect)
    }

    /// The fractional part, for cheap seeded scatter.
    static func fraction(_ value: Double) -> Double {
        value - floor(value)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
