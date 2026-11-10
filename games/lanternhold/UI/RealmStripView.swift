import SwiftUI

/// The realm strip (DESIGN.md "Controls"; M2b part 2): a slim map of the whole world at the top centre, drawn as a
/// strip cut from the realm map (docs/UI-look.md): parchment inside an ink rule with a scale along its foot. The gorge
/// is a wash of ink with the darkness bank's black at its mouth, the Great Beacon in gold, the three lines' walls by
/// state (standing in ink, damaged in wax red, rubble a red cross, being built in gold, an empty open site dashed),
/// the castle's towers, the town's red roofs on the valley's green, the river in House Lantern's teal; a frame for
/// what is on screen, the lord's teal mark, where he walks to, and at night the creatures as embers; by day (M3) a
/// wax-red tag over the great hall with the number of petitioners waiting and the Stranger's grey lantern at the front
/// gate. The map spans the strip's whole width, so a tap at a share of it walks the king to that share of the world
/// (`realm-strip`; 44 pt tall to tap).
struct RealmStripView: View {
    static let height: CGFloat = 44
    static let barHeight: CGFloat = 26

    let strip: RealmStrip
    let reduceMotion: Bool
    let onTap: @MainActor (Double) -> Void

    init(strip: RealmStrip, reduceMotion: Bool, onTap: @escaping @MainActor (Double) -> Void) {
        self.strip = strip
        self.reduceMotion = reduceMotion
        self.onTap = onTap
    }

    var body: some View {
        let snapshot = strip
        return GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            Canvas { context, size in
                RealmStripView.draw(snapshot, in: &context, size: size)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                onTap(Double(min(1, max(0, location.x / width))))
            }
        }
        .frame(height: RealmStripView.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Map of the valley"))
        .accessibilityValue(snapshot.petitioners > 0 ? Text("Petitioners waiting: \(snapshot.petitioners)")
                                                     : Text(verbatim: ""))
        .accessibilityHint(Text("Tap to walk there"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("realm-strip")
    }

    /// Draws the strip into a canvas of `size` (the bar is centred vertically).
    static func draw(_ strip: RealmStrip, in context: inout GraphicsContext, size: CGSize) {
        let top = (size.height - barHeight) / 2
        let bar = CGRect(x: 0, y: top, width: size.width, height: barHeight)
        let outline = Path(roundedRect: bar, cornerRadius: 2)
        func x(_ fraction: Double) -> CGFloat { CGFloat(fraction) * size.width }
        func band(_ range: ClosedRange<Double>, inset: CGFloat = 0) -> CGRect {
            CGRect(x: x(range.lowerBound), y: top + inset, width: x(range.upperBound) - x(range.lowerBound),
                   height: barHeight - 2 * inset)
        }
        let ink = Theme.ink

        // The sheet.
        context.fill(outline, with: .linearGradient(Gradient(colors: [Theme.parchment, Theme.parchmentMid]),
                                                    startPoint: CGPoint(x: 0, y: bar.minY),
                                                    endPoint: CGPoint(x: 0, y: bar.maxY)))
        var map = context
        map.clip(to: outline)
        // Washes of colour: the gorge, the castle, the valley and the river.
        map.fill(Path(band(0...RealmStrip.castle.lowerBound)), with: .color(Theme.inkSoft.opacity(0.42)))
        map.fill(Path(band(RealmStrip.castle)), with: .color(Theme.stone.opacity(0.42)))
        map.fill(Path(band(RealmStrip.town)), with: .color(Theme.meadow.opacity(0.55)))
        map.fill(Path(band(RealmStrip.river)), with: .color(Theme.teal.opacity(0.8)))
        // The ground line, and under it the map's scale.
        let ground = top + barHeight - 4
        map.fill(Path(CGRect(x: 0, y: ground, width: size.width, height: 1)), with: .color(ink.opacity(0.6)))
        var ticks = Path()
        for step in 1..<32 {
            let tx = (size.width * CGFloat(step) / 32).rounded() + 0.5
            ticks.move(to: CGPoint(x: tx, y: ground + 1))
            ticks.addLine(to: CGPoint(x: tx, y: ground + (step % 4 == 0 ? 4 : 2.5)))
        }
        map.stroke(ticks, with: .color(ink.opacity(0.45)), lineWidth: 1)
        // The castle's towers and keep rise above its walls; the town's roofs.
        let towers: [(Double, CGFloat, CGFloat)] = [(1268, 4, 13), (1360, 6, 18), (1450, 4, 13), (2330, 4, 11)]
        for (worldX, half, height) in towers {
            let cx = x(RealmStrip.fraction(worldX))
            let tower = Path(CGRect(x: cx - half, y: ground - height, width: half * 2, height: height))
            map.fill(tower, with: .color(Theme.plaque))
            map.stroke(tower, with: .color(ink), lineWidth: 1)
        }
        for worldX in [2512.0, 2832, 2932, 3122, 3245, 3365] {
            let cx = x(RealmStrip.fraction(worldX))
            var roof = Path()
            roof.move(to: CGPoint(x: cx - 4.5, y: ground - 4))
            roof.addLine(to: CGPoint(x: cx, y: ground - 9.5))
            roof.addLine(to: CGPoint(x: cx + 4.5, y: ground - 4))
            roof.closeSubpath()
            map.fill(Path(CGRect(x: cx - 3, y: ground - 4, width: 6, height: 4)), with: .color(Theme.plaque))
            map.fill(roof, with: .color(Theme.rubric))
            map.stroke(roof, with: .color(ink.opacity(0.8)), lineWidth: 0.75)
        }
        // The darkness bank at the Gloom's mouth: spilt ink.
        if strip.bank > 0 {
            let edge = x(strip.bank)
            map.fill(Path(CGRect(x: 0, y: top, width: edge, height: barHeight)), with: .color(Theme.desk.opacity(0.9)))
            let fade = CGRect(x: edge, y: top, width: 10, height: barHeight)
            map.fill(Path(fade), with: .linearGradient(Gradient(colors: [Theme.desk.opacity(0.7), .clear]),
                                                       startPoint: CGPoint(x: fade.minX, y: 0),
                                                       endPoint: CGPoint(x: fade.maxX, y: 0)))
        }
        // The Great Beacon: its fire when lit, its tower by stage, a faint mark once its site is open.
        let beaconX = x(RealmStrip.beaconPosition)
        if strip.beaconLit {
            let glow = CGRect(x: beaconX - 9, y: top + 2, width: 18, height: 18)
            map.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [Theme.goldHi, Theme.fireOrange.opacity(0.55), .clear]),
                center: CGPoint(x: glow.midX, y: glow.midY), startRadius: 0, endRadius: 9))
        }
        if strip.beaconStage > 0 {
            let height = CGFloat(5 + 4 * strip.beaconStage)
            let tower = Path(CGRect(x: beaconX - 2.5, y: ground - height, width: 5, height: height))
            map.fill(tower, with: .color(strip.beaconLit ? Theme.goldHi : Theme.plaque))
            map.stroke(tower, with: .color(ink), lineWidth: 1)
        } else if strip.beaconOpen {
            map.stroke(Path(ellipseIn: CGRect(x: beaconX - 3, y: ground - 6, width: 6, height: 6)),
                       with: .color(Theme.gold), lineWidth: 1.25)
        }
        // The lines' walls, each on a sliver of bare paper so the bank's ink never swallows it.
        for line in strip.lines {
            let lx = x(line.position)
            let rect = CGRect(x: lx - 2, y: top + 6, width: 4, height: barHeight - 10)
            let paper = Path(rect.insetBy(dx: -1, dy: -1))
            switch line.mark {
            case .locked:
                break
            case .empty:
                map.stroke(Path(rect), with: .color(ink.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            case .building:
                map.fill(paper, with: .color(Theme.plaque))
                map.fill(Path(rect), with: .color(Theme.gold))
                map.stroke(Path(rect), with: .color(ink), lineWidth: 0.75)
            case .standing:
                map.fill(paper, with: .color(Theme.plaque))
                map.fill(Path(rect), with: .color(ink))
            case .damaged:
                map.fill(paper, with: .color(Theme.plaque))
                map.fill(Path(rect), with: .color(Theme.rubricHi))
                map.stroke(Path(rect), with: .color(ink), lineWidth: 0.75)
            case .rubble:
                var cross = Path()
                cross.move(to: CGPoint(x: lx - 3.5, y: ground - 8))
                cross.addLine(to: CGPoint(x: lx + 3.5, y: ground - 1))
                cross.move(to: CGPoint(x: lx + 3.5, y: ground - 8))
                cross.addLine(to: CGPoint(x: lx - 3.5, y: ground - 1))
                map.stroke(cross, with: .color(Theme.plaque), lineWidth: 3.5)
                map.stroke(cross, with: .color(Theme.rubric), lineWidth: 2)
            }
        }
        // M3: the Stranger at the front gate (her grey lantern); the petitioners' tag comes last, over the bar.
        if strip.strangerAtGate {
            let gx = x(RealmStrip.gatePosition)
            let glow = CGRect(x: gx - 6, y: ground - 13, width: 12, height: 12)
            map.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.95), Color(hex: 0xB8C4E0).opacity(0.6), .clear]),
                center: CGPoint(x: glow.midX, y: glow.midY), startRadius: 0, endRadius: 6))
            let lantern = Path(ellipseIn: CGRect(x: gx - 2, y: ground - 9, width: 4, height: 4))
            map.fill(lantern, with: .color(.white))
            map.stroke(lantern, with: .color(ink), lineWidth: 0.75)
        }
        // At night: the creatures as embers along the floor.
        for fraction in strip.creatures {
            let cx = x(fraction)
            map.fill(Path(ellipseIn: CGRect(x: cx - 2, y: ground - 1, width: 4, height: 4)),
                     with: .color(Color(hex: 0xE0481C)))
        }
        // What is on screen: a window of clean paper inside an ink line.
        if let window = strip.window {
            let frame = Path(roundedRect: band(window, inset: 1.5), cornerRadius: 1)
            map.fill(frame, with: .color(Color.white.opacity(0.16)))
            map.stroke(frame, with: .color(ink.opacity(0.85)), lineWidth: 1)
        }
        // Where the lord walks to, and the lord: House Lantern's teal on a hair of bare paper.
        if let target = strip.target {
            let tx = x(target)
            var diamond = Path()
            diamond.move(to: CGPoint(x: tx, y: ground - 7))
            diamond.addLine(to: CGPoint(x: tx + 3.5, y: ground - 3.5))
            diamond.addLine(to: CGPoint(x: tx, y: ground))
            diamond.addLine(to: CGPoint(x: tx - 3.5, y: ground - 3.5))
            diamond.closeSubpath()
            map.fill(diamond, with: .color(Theme.goldHi))
            map.stroke(diamond, with: .color(ink), lineWidth: 0.75)
        }
        let kx = x(strip.king)
        var mark = Path()
        mark.move(to: CGPoint(x: kx - 5.5, y: top + 2.5))
        mark.addLine(to: CGPoint(x: kx + 5.5, y: top + 2.5))
        mark.addLine(to: CGPoint(x: kx, y: top + 9.5))
        mark.closeSubpath()
        let staff = Path(CGRect(x: kx - 1, y: top + 3, width: 2, height: barHeight - 7))
        map.stroke(staff, with: .color(Theme.plaque), lineWidth: 1.5)
        map.stroke(mark, with: .color(Theme.plaque), lineWidth: 1.5)
        map.fill(staff, with: .color(Theme.teal))
        map.fill(mark, with: .color(Theme.teal))
        context.stroke(outline, with: .color(Theme.rule), lineWidth: 1.5)
        // M3: the petitioners waiting for the throne: a wax-red tag with their number over the great hall, above the
        // bar so the lord's mark never hides it.
        if strip.petitioners > 0 {
            let hx = x(RealmStrip.hallPosition)
            let bubble = CGRect(x: hx - 8, y: max(0, top - 9), width: 16, height: 13)
            var tail = Path()
            tail.move(to: CGPoint(x: hx - 3, y: bubble.maxY - 0.5))
            tail.addLine(to: CGPoint(x: hx + 3, y: bubble.maxY - 0.5))
            tail.addLine(to: CGPoint(x: hx, y: bubble.maxY + 4))
            tail.closeSubpath()
            context.fill(tail, with: .color(Theme.rubric))
            context.fill(Path(roundedRect: bubble, cornerRadius: 2), with: .color(Theme.rubric))
            context.stroke(Path(roundedRect: bubble, cornerRadius: 2), with: .color(Theme.rubricDeep), lineWidth: 1)
            context.draw(Text(verbatim: "\(strip.petitioners)")
                .font(Theme.figures(11))
                .foregroundStyle(Theme.sealWords), at: CGPoint(x: hx, y: bubble.midY))
        }
    }
}
