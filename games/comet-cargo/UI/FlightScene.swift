import SwiftUI

/// Something that lives for a few seconds in the scene, spawned by a sim event.
struct SceneEffect: Sendable, Identifiable {
    enum Kind: Sendable {
        /// A dropped stage tumbling away.
        case debris(stage: Int, scale: Double, side: Double)
        /// A released satellite: unfolds and glides onto its ring, or tumbles away dimmed when `ring` is nil.
        case satellite(ring: Int?, side: Double)
        /// A rating pop-up near the rocket.
        case popup(text: String, tint: Color)
    }

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
}

/// Maps altitudes to screen rows. The rocket's reference point sits at 60 % of the screen height; the world scrolls.
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

/// The rocket's parts in screen points, relative to its reference point (0, 0).
struct RocketLayout {
    /// One rect per stage of the whole rocket, bottom first.
    var stages: [CGRect]
    var nose: CGRect
    var fullHeight: CGFloat

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
        var y = fullHeight / 2
        var rects: [CGRect] = []
        for size in raw {
            let w = size.width * fit
            let h = size.height * fit
            y -= h
            rects.append(CGRect(x: -w / 2, y: y, width: w, height: h))
        }
        stages = rects
        let noseW = topWidth * fit
        let noseH = noseHeight * fit
        nose = CGRect(x: -noseW / 2, y: y - noseH, width: noseW, height: noseH)
    }
}

/// Draws the flight: sky by altitude, stars, the curving planet, clouds, rings, apex lines, the rocket with flame and
/// smoke, and the effects. Pure drawing: it reads a SceneState and changes nothing.
enum FlightScene {
    static func draw(_ context: inout GraphicsContext, size: CGSize, state: SceneState) {
        let camera = SceneCamera(size: size, altitude: state.altitude, span: state.span)
        let layout = RocketLayout(scales: state.stageScales, maxHeight: min(240, size.height * 0.28))
        var ctx = context
        if !state.reduceMotion && state.sinceDrop < 0.25 {
            let k = CGFloat(1 - state.sinceDrop / 0.25)
            ctx.translateBy(x: 0, y: 5 * k)
        }
        drawSky(ctx, camera: camera)
        drawStars(ctx, camera: camera, state: state)
        drawPlanet(ctx, camera: camera, layout: layout, state: state)
        drawClouds(ctx, camera: camera, state: state)
        drawRings(ctx, camera: camera, state: state)
        drawApexLines(ctx, camera: camera, state: state)
        drawSmoke(ctx, camera: camera, layout: layout, state: state)
        drawEffects(ctx, camera: camera, layout: layout, state: state, popups: false)
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
        let groundY = camera.y(0) + layout.fullHeight / 2
        let lifted = log10(1 + state.altitude / 5) / 2.3
        let rise = CGFloat(min(1, max(0, lifted)))
        let limbY = h * (0.97 - 0.13 * rise)
        let horizonY = max(groundY, limbY)
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
        let surface = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [Palette.skyTealRGB.mix(Palette.groundRGB, 0.5).color, Palette.groundRGB.color, Palette.navyRGB.mix(Palette.groundRGB, 0.5).color]),
            startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: horizonY + min(radius, h)))
        ctx.fill(Path(ellipseIn: disc), with: surface)
        // Cream cloud bands on the planet, seen from above.
        if rise > 0.15 {
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

    static func drawClouds(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        let w = camera.size.width
        let h = camera.size.height
        let drift = state.reduceMotion ? 0 : CGFloat(state.clock * 4)
        for index in 0..<22 {
            let alt = 3 + 12 * fraction(Double(index) * 0.6180339 + 0.05)
            let y = camera.y(alt)
            let scale = CGFloat(0.7 + 0.6 * fraction(Double(index) * 0.371))
            let cw = 90 * scale
            guard y > -60, y < h + 60 else { continue }
            let span = w + cw * 2
            let base = CGFloat(fraction(Double(index) * 0.7548777)) * span
            let speed = CGFloat(0.5 + fraction(Double(index) * 0.29))
            let x = (base + drift * speed).truncatingRemainder(dividingBy: span) - cw
            let near = fraction(Double(index) * 0.53) > 0.5
            let tint = near ? Palette.paper : Palette.cream
            let alpha = near ? 0.92 : 0.7
            drawCloud(ctx, at: CGPoint(x: x, y: y), width: cw, color: tint.opacity(alpha))
        }
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
        for ring in 0..<Rings.count {
            let center = Rings.altitudes[ring]
            let half = Rings.halfWidth(ring)
            let yTop = camera.y(center + half)
            let yBottom = camera.y(center - half)
            guard yBottom > -40, yTop < h + 40 else { continue }
            let y = camera.y(center)
            let complete = ring < state.ringDeliveries.count && state.ringDeliveries[ring] >= Economy.ringSlots
            let tint = complete ? Palette.gold : Palette.mustard
            let band = CGRect(x: 0, y: yTop, width: w, height: max(2, yBottom - yTop))
            ctx.fill(Path(band), with: .linearGradient(
                Gradient(colors: [tint.opacity(0), tint.opacity(0.16), tint.opacity(0)]),
                startPoint: CGPoint(x: 0, y: band.minY), endPoint: CGPoint(x: 0, y: band.maxY)))
            // Perfect zone: a slightly brighter strip.
            let perfectHalf = half * Ratings.perfectRelease
            let pTop = camera.y(center + perfectHalf)
            let pBottom = camera.y(center - perfectHalf)
            ctx.fill(Path(CGRect(x: 0, y: pTop, width: w, height: max(1, pBottom - pTop))), with: .color(tint.opacity(0.12)))
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            ctx.stroke(line, with: .color(tint.opacity(0.25)), lineWidth: 9)
            ctx.stroke(line, with: .color(tint.opacity(0.5)), lineWidth: 4)
            ctx.stroke(line, with: .color(Palette.paper.opacity(0.95)), lineWidth: 1.5)
            drawRingLabel(ctx, ring: ring, y: y, tint: tint)
            // Satellites already delivered here drift along the line.
            let count = ring < state.ringDeliveries.count ? min(Economy.ringSlots, state.ringDeliveries[ring]) : 0
            for index in 0..<count {
                let seed = fraction(Double(ring) * 0.37 + Double(index) * 0.21)
                let speed = 0.012 + 0.006 * Double(index)
                let moving = state.reduceMotion ? 0 : state.clock * speed
                let x = CGFloat(fraction(seed + moving)) * w
                SatelliteShape.draw(in: ctx, at: CGPoint(x: x, y: y), size: 18)
            }
        }
    }

    static func drawRingLabel(_ ctx: GraphicsContext, ring: Int, y: CGFloat, tint: Color) {
        let km = Int(Rings.altitudes[ring])
        let title = Text("Ring \(ring + 1)").font(.rounded(13, .heavy)).foregroundStyle(tint)
        let detail = Text("\(km) km").font(.rounded(12, .bold)).foregroundStyle(Palette.paper.opacity(0.9))
        let pay = Text(verbatim: "\(Rings.basePay(ring))").font(.rounded(12, .heavy).monospacedDigit()).foregroundStyle(Palette.mustard)
        let plate = CGRect(x: 52, y: y - 40, width: 92, height: 34)
        ctx.fill(Path(roundedRect: plate, cornerRadius: 9), with: .color(Palette.night.opacity(0.55)))
        ctx.draw(title, at: CGPoint(x: plate.minX + 8, y: plate.minY + 10), anchor: .leading)
        ctx.draw(detail, at: CGPoint(x: plate.minX + 8, y: plate.minY + 25), anchor: .leading)
        ctx.draw(pay, at: CGPoint(x: plate.maxX - 8, y: plate.minY + 25), anchor: .trailing)
        CoinIcon.draw(in: ctx, center: CGPoint(x: plate.maxX - 12, y: plate.minY + 10), radius: 5)
    }

    static func drawApexLines(_ ctx: GraphicsContext, camera: SceneCamera, state: SceneState) {
        let w = camera.size.width
        let entries: [(Double, String, Color)] = [
            (state.best, String(localized: "Best"), Palette.coral),
            (state.last ?? 0, String(localized: "Last"), Palette.paper),
        ]
        for (alt, label, color) in entries where alt > 1 {
            if label != String(localized: "Best") && abs(alt - state.best) < 0.5 { continue }
            let y = camera.y(alt)
            guard y > -10, y < camera.size.height + 10 else { continue }
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            ctx.stroke(line, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, dash: [6, 6]))
            let text = Text(verbatim: "\(label) \(Int(alt.rounded())) km").font(.rounded(11, .heavy)).foregroundStyle(color)
            ctx.draw(text, at: CGPoint(x: w - 10, y: y - 9), anchor: .trailing)
        }
    }

    // MARK: Rocket

    static func drawRocket(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, state: SceneState) {
        var rocket = ctx
        rocket.translateBy(x: camera.size.width / 2, y: camera.rocketY)
        let attached = Array(state.stageIndex..<layout.stages.count)
        guard let bottomIndex = attached.first else { return }
        let bottom = layout.stages[bottomIndex]
        if state.phase == .burning {
            drawFlame(rocket, below: bottom, clock: state.clock, calm: state.reduceMotion)
        }
        drawNozzle(rocket, under: bottom)
        drawFins(rocket, on: bottom)
        for index in attached.reversed() {
            drawStage(rocket, rect: layout.stages[index], index: index, isTop: index == layout.stages.count - 1, dim: false)
        }
        drawNose(rocket, rect: layout.nose)
    }

    static func bodyShading(_ rect: CGRect, dim: Bool) -> GraphicsContext.Shading {
        let edge = Palette.creamRGB.mix(Palette.inkRGB, dim ? 0.35 : 0.14).color
        let mid = dim ? Palette.creamRGB.mix(Palette.inkRGB, 0.2).color : Palette.paper
        return .linearGradient(Gradient(colors: [edge, mid, mid, edge]),
                               startPoint: CGPoint(x: rect.minX, y: 0), endPoint: CGPoint(x: rect.maxX, y: 0))
    }

    static func drawStage(_ ctx: GraphicsContext, rect: CGRect, index: Int, isTop: Bool, dim: Bool) {
        let corner = min(7, rect.width * 0.18)
        let body = Path(roundedRect: rect, cornerRadius: corner)
        ctx.fill(body, with: bodyShading(rect, dim: dim))
        var banded = ctx
        banded.clip(to: body)
        let bandColor = index % 2 == 0 ? Palette.coral : Palette.deepTeal
        let bandHeight = max(3, rect.height * 0.16)
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
        for j in 0..<16 {
            let age = phase + Double(j) * period
            let id = emitted - Double(j)
            let wobble = CGFloat(sin(id * 1.7)) * CGFloat(6 + age * 26)
            let fall = speedPx * CGFloat(age) + CGFloat(age * 30)
            let r = CGFloat(7 + age * 24)
            let alpha = 0.5 * thin * max(0, 1 - age / 1.1)
            guard alpha > 0.01 else { continue }
            let rect = CGRect(x: cx + wobble - r, y: startY + fall - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(alpha)))
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
                let fallKm = effect.altitude + effect.speed * age - 0.5 * FlightSim.gravity * age * age
                let shift = CGFloat(state.altitude - fallKm) * camera.pxPerKm
                let y = camera.rocketY + rect.midY + shift
                guard y < camera.size.height + 200 else { continue }
                let x = cx + CGFloat(side) * CGFloat(12 + age * 30)
                var piece = ctx
                piece.translateBy(x: x, y: y)
                piece.rotate(by: .radians(side * age * 1.3))
                piece.opacity = max(0, 1 - age / 5)
                let local = CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height)
                drawStage(piece, rect: local, index: stage, isTop: false, dim: true)
            case .satellite(let ring, let side):
                guard !popups else { continue }
                drawSatelliteEffect(ctx, camera: camera, layout: layout, effect: effect, ring: ring, side: side, age: age, state: state)
            case .popup(let text, let tint):
                guard popups, age < 1.4 else { continue }
                let rise = CGFloat(age * 28)
                let y = camera.rocketY - layout.fullHeight / 2 - 26 - rise
                let pop = state.reduceMotion ? 1 : 1 + 0.35 * max(0, 1 - age / 0.15)
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

    static func drawSatelliteEffect(_ ctx: GraphicsContext, camera: SceneCamera, layout: RocketLayout, effect: SceneEffect,
                                    ring: Int?, side: Double, age: Double, state: SceneState) {
        let cx = camera.size.width / 2
        let s = CGFloat(side)
        let popTime = 0.45
        let startY = camera.y(effect.altitude) + layout.nose.maxY
        if age <= popTime {
            let t = age / popTime
            let eased = CGFloat(1 - pow(1 - t, 3))
            let x = cx + s * (16 + 70 * eased)
            let y = startY - 14 * CGFloat(sin(t * Double.pi))
            SatelliteShape.draw(in: ctx, at: CGPoint(x: x, y: y), size: 26, unfold: t)
            return
        }
        let popX = cx + s * 86
        if let ring {
            let glide = min(1, (age - popTime) / 1.1)
            let eased = 1 - pow(1 - glide, 2)
            let target = Rings.altitudes[ring]
            let startAlt = camera.altitude(atY: startY)
            let alt = startAlt + (target - startAlt) * eased
            let drift = s * CGFloat(max(0, age - popTime - 1.1) * 14)
            let x = popX + s * 30 * CGFloat(eased) + drift
            let y = camera.y(alt)
            guard y > -30, y < camera.size.height + 30 else { return }
            SatelliteShape.draw(in: ctx, at: CGPoint(x: x, y: y), size: 26 - 6 * CGFloat(eased))
        } else {
            let t = age - popTime
            guard t < 3 else { return }
            let x = popX + s * CGFloat(t * 40)
            let y = startY + CGFloat(t * t * 90)
            var dimmed = ctx
            dimmed.opacity = max(0, 1 - t / 3)
            SatelliteShape.draw(in: dimmed, at: CGPoint(x: x, y: y), size: 22, dim: true, angle: t * 4 * side)
        }
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
