import SwiftUI

/// The ring network around the planet: 15 concentric rings on a log scale, delivered satellites orbiting slowly (up to 5
/// per ring), rings above the best apex faint, the next ring to reach dashed in mustard, completed rings gold.
struct NetworkView: View {
    let deliveries: [Int]
    let bestApex: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(deliveries: [Int], bestApex: Double) {
        self.deliveries = deliveries
        self.bestApex = bestApex
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                NetworkDrawing.draw(context, size: size, deliveries: deliveries, bestApex: bestApex, time: time)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Ring network"))
        .accessibilityValue(Text("\(completedCount) of 15 rings complete"))
    }

    private var completedCount: Int {
        deliveries.filter { $0 >= Economy.ringSlots }.count
    }

}

/// The network drawing, a plain enum so it carries no actor isolation.
enum NetworkDrawing {
    /// The lowest ring above the best apex: the next goal.
    static func nextRing(bestApex: Double) -> Int? {
        (0..<Rings.count).first { Rings.altitudes[$0] > bestApex }
    }

    /// Radius of ring `k` between the planet and the edge, on a log scale of its altitude.
    static func radius(_ ring: Int, planet: CGFloat, outer: CGFloat) -> CGFloat {
        let low = log(12.0)
        let high = log(1000.0)
        let t = (log(Rings.altitudes[ring]) - low) / (high - low)
        return planet + 6 + (outer - planet - 6) * CGFloat(t)
    }

    static func draw(_ context: GraphicsContext, size: CGSize, deliveries: [Int], bestApex: Double, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = min(size.width, size.height) / 2 - 8
        let painted = ArtAsset.image(ArtName.planet)
        // The painted planet is drawn a little bigger than the procedural disc, so its bands read in the card.
        let planet = outer * (painted == nil ? 0.17 : 0.21)
        let next = nextRing(bestApex: bestApex)
        // Soft stars behind.
        for index in 0..<46 {
            let fx = FlightScene.fraction(Double(index) * 0.6180339 + 0.2)
            let fy = FlightScene.fraction(Double(index) * 0.4142135 + 0.5)
            let r: CGFloat = index % 7 == 0 ? 1.6 : 0.9
            let rect = CGRect(x: CGFloat(fx) * size.width, y: CGFloat(fy) * size.height, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(0.5)))
        }
        for ring in 0..<Rings.count {
            let r = radius(ring, planet: planet, outer: outer)
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            let count = ring < deliveries.count ? max(0, deliveries[ring]) : 0
            let complete = count >= Economy.ringSlots
            let reached = Rings.altitudes[ring] <= bestApex
            if complete {
                context.stroke(Path(ellipseIn: rect), with: .color(Palette.gold.opacity(0.3)), lineWidth: 6)
                context.stroke(Path(ellipseIn: rect), with: .color(Palette.gold), lineWidth: 2.2)
            } else if reached {
                context.stroke(Path(ellipseIn: rect), with: .color(Palette.mustard.opacity(0.75)), lineWidth: 1.4)
            } else if ring == next {
                context.stroke(Path(ellipseIn: rect), with: .color(Palette.mustard),
                               style: StrokeStyle(lineWidth: 1.6, dash: [4, 4]))
            } else {
                context.stroke(Path(ellipseIn: rect), with: .color(Palette.paper.opacity(0.1)), lineWidth: 1)
            }
            let shown = min(Economy.ringSlots, count)
            let speed = 0.5 / pow(Double(r / planet), 1.5)
            for index in 0..<max(0, shown) {
                let slotAngle: Double = Double(index) * 2.0 * Double.pi / Double(Economy.ringSlots)
                let angle: Double = slotAngle + Double(ring) * 0.9 + time * speed
                let p = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
                let dot = CGRect(x: p.x - 3.2, y: p.y - 3.2, width: 6.4, height: 6.4)
                context.fill(Path(ellipseIn: dot), with: .color(complete ? Palette.gold : Palette.paper))
            }
        }
        // Best apex as a coral dashed circle.
        if bestApex > 12 {
            let low = log(12.0)
            let high = log(1000.0)
            let t = min(1.04, max(0, (log(bestApex) - low) / (high - low)))
            let r = planet + 6 + (outer - planet - 6) * CGFloat(t)
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            context.stroke(Path(ellipseIn: rect), with: .color(Palette.coral.opacity(0.85)), style: StrokeStyle(lineWidth: 1.5, dash: [2, 4]))
        }
        // The planet.
        let disc = CGRect(x: center.x - planet, y: center.y - planet, width: planet * 2, height: planet * 2)
        context.fill(Path(ellipseIn: disc.insetBy(dx: -5, dy: -5)), with: .color(Palette.skyTeal.opacity(0.25)))
        if let painted {
            drawPaintedPlanet(context, art: painted, disc: disc)
            return
        }
        context.fill(Path(ellipseIn: disc), with: .linearGradient(
            Gradient(colors: [Palette.skyTeal, Palette.groundRGB.color]),
            startPoint: CGPoint(x: disc.minX, y: disc.minY), endPoint: CGPoint(x: disc.maxX, y: disc.maxY)))
        var bands = context
        bands.clip(to: Path(ellipseIn: disc))
        for index in 0..<3 {
            let y = disc.minY + disc.height * CGFloat(0.3 + 0.2 * Double(index))
            var band = Path()
            band.move(to: CGPoint(x: disc.minX, y: y))
            band.addQuadCurve(to: CGPoint(x: disc.maxX, y: y + 4), control: CGPoint(x: disc.midX, y: y - 6))
            bands.stroke(band, with: .color(Palette.cream.opacity(0.45)), lineWidth: 3)
        }
        context.stroke(Path(ellipseIn: disc), with: .color(Palette.paper.opacity(0.6)), lineWidth: 1.5)
    }

    /// The painted planet (ART.md): its disc fills 92.6 % of the square picture, the rest is its soft atmosphere rim, so
    /// the picture is drawn a little larger than the disc to put the painted limb on the disc's edge.
    static func drawPaintedPlanet(_ context: GraphicsContext, art: Image, disc: CGRect) {
        let grow = disc.width * (1 / 0.926 - 1) / 2
        context.draw(art, in: disc.insetBy(dx: -grow, dy: -grow))
    }
}
