import SwiftUI

/// The realm strip (DESIGN.md "Controls"; M2b part 2): a slim map of the whole world at the top centre. The gorge in
/// violet with the darkness bank's black at its mouth, the Great Beacon, the three lines' walls by state (standing,
/// damaged, rubble, being built, an empty open site), the castle's towers in stone, the town's roofs on the valley's
/// green, the river; a frame for what is on screen, the king's gold mark, where he walks to, and at night the
/// creatures as embers; by day (M3) a parchment bubble over the great hall with the number of petitioners waiting and
/// the Stranger's grey lantern at the front gate. The map spans the strip's whole width, so a tap at a share of it
/// walks the king to that share of the world (`realm-strip`; 44 pt tall to tap).
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
        .accessibilityLabel(Text("Map of the realm"))
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
        let outline = Path(roundedRect: bar, cornerRadius: barHeight / 2)
        func x(_ fraction: Double) -> CGFloat { CGFloat(fraction) * size.width }
        func band(_ range: ClosedRange<Double>, inset: CGFloat = 0) -> CGRect {
            CGRect(x: x(range.lowerBound), y: top + inset, width: x(range.upperBound) - x(range.lowerBound),
                   height: barHeight - 2 * inset)
        }

        context.fill(outline, with: .color(Theme.night0.opacity(0.72)))
        var map = context
        map.clip(to: outline)
        // The gorge, the castle, the valley and the river.
        map.fill(Path(band(0...RealmStrip.castle.lowerBound)), with: .color(Theme.night2.opacity(0.95)))
        map.fill(Path(band(RealmStrip.castle)), with: .color(Theme.stone.opacity(0.9)))
        map.fill(Path(band(RealmStrip.town)), with: .color(Theme.meadow.opacity(0.85)))
        map.fill(Path(band(RealmStrip.river)), with: .color(Theme.teal))
        // The castle's towers and keep rise above its walls; the town's roofs.
        let ground = top + barHeight - 4
        let towers: [(Double, CGFloat, CGFloat)] = [(1268, 4, 13), (1360, 6, 18), (1450, 4, 13), (2330, 4, 11)]
        for (worldX, half, height) in towers {
            let cx = x(RealmStrip.fraction(worldX))
            map.fill(Path(CGRect(x: cx - half, y: ground - height, width: half * 2, height: height)),
                     with: .color(Theme.stoneLight))
        }
        for worldX in [2512.0, 2832, 2932, 3122, 3245, 3365] {
            let cx = x(RealmStrip.fraction(worldX))
            var roof = Path()
            roof.move(to: CGPoint(x: cx - 4, y: ground - 4))
            roof.addLine(to: CGPoint(x: cx, y: ground - 9))
            roof.addLine(to: CGPoint(x: cx + 4, y: ground - 4))
            roof.closeSubpath()
            map.fill(roof, with: .color(Color(hex: 0x9A4A32)))
            map.fill(Path(CGRect(x: cx - 3, y: ground - 4, width: 6, height: 4)), with: .color(Theme.parchmentDeep))
        }
        // The darkness bank at the Gloom's mouth.
        if strip.bank > 0 {
            let edge = x(strip.bank)
            map.fill(Path(CGRect(x: 0, y: top, width: edge, height: barHeight)), with: .color(Color.black.opacity(0.82)))
            let fade = CGRect(x: edge, y: top, width: 10, height: barHeight)
            map.fill(Path(fade), with: .linearGradient(Gradient(colors: [Color.black.opacity(0.6), .clear]),
                                                       startPoint: CGPoint(x: fade.minX, y: 0),
                                                       endPoint: CGPoint(x: fade.maxX, y: 0)))
        }
        // The Great Beacon: its fire when lit, its tower by stage, a faint mark once its site is open.
        let beaconX = x(RealmStrip.beaconPosition)
        if strip.beaconLit {
            let glow = CGRect(x: beaconX - 9, y: top + 2, width: 18, height: 18)
            map.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [Theme.fireGold, Theme.fireOrange.opacity(0.5), .clear]),
                center: CGPoint(x: glow.midX, y: glow.midY), startRadius: 0, endRadius: 9))
        }
        if strip.beaconStage > 0 {
            let height = CGFloat(5 + 4 * strip.beaconStage)
            map.fill(Path(CGRect(x: beaconX - 2.5, y: ground - height, width: 5, height: height)),
                     with: .color(Theme.parchmentDeep))
        } else if strip.beaconOpen {
            map.stroke(Path(ellipseIn: CGRect(x: beaconX - 3, y: ground - 6, width: 6, height: 6)),
                       with: .color(Theme.parchment.opacity(0.7)), lineWidth: 1)
        }
        // The lines' walls.
        for line in strip.lines {
            let lx = x(line.position)
            let rect = CGRect(x: lx - 2, y: top + 6, width: 4, height: barHeight - 10)
            switch line.mark {
            case .locked:
                break
            case .empty:
                map.stroke(Path(rect), with: .color(Theme.parchment.opacity(0.55)), lineWidth: 1)
            case .building:
                map.fill(Path(rect), with: .color(Theme.gold.opacity(0.75)))
            case .standing:
                map.fill(Path(rect), with: .color(Theme.parchment))
            case .damaged:
                map.fill(Path(rect), with: .color(Theme.fireOrange))
            case .rubble:
                var cross = Path()
                cross.move(to: CGPoint(x: lx - 3.5, y: ground - 8))
                cross.addLine(to: CGPoint(x: lx + 3.5, y: ground - 1))
                cross.move(to: CGPoint(x: lx + 3.5, y: ground - 8))
                cross.addLine(to: CGPoint(x: lx - 3.5, y: ground - 1))
                map.stroke(cross, with: .color(Color(hex: 0xFF5A3A)), lineWidth: 2)
            }
        }
        // M3: the Stranger at the front gate (her grey lantern); the petitioners' bubble comes last, over the bar.
        if strip.strangerAtGate {
            let gx = x(RealmStrip.gatePosition)
            let glow = CGRect(x: gx - 6, y: ground - 13, width: 12, height: 12)
            map.fill(Path(ellipseIn: glow), with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.95), Color(hex: 0xB8C4E0).opacity(0.55), .clear]),
                center: CGPoint(x: glow.midX, y: glow.midY), startRadius: 0, endRadius: 6))
            map.fill(Path(ellipseIn: CGRect(x: gx - 1.5, y: ground - 8.5, width: 3, height: 3)), with: .color(.white))
        }
        // At night: the creatures as embers along the floor.
        for fraction in strip.creatures {
            let cx = x(fraction)
            map.fill(Path(ellipseIn: CGRect(x: cx - 2, y: ground - 1, width: 4, height: 4)),
                     with: .color(Color(hex: 0xFF6A3D)))
        }
        // What is on screen.
        if let window = strip.window {
            let frame = band(window, inset: 1.5)
            map.stroke(Path(roundedRect: frame, cornerRadius: 4), with: .color(Theme.parchment.opacity(0.55)),
                       lineWidth: 1)
        }
        // Where the king walks to, and the king.
        if let target = strip.target {
            let tx = x(target)
            var diamond = Path()
            diamond.move(to: CGPoint(x: tx, y: ground - 7))
            diamond.addLine(to: CGPoint(x: tx + 3.5, y: ground - 3.5))
            diamond.addLine(to: CGPoint(x: tx, y: ground))
            diamond.addLine(to: CGPoint(x: tx - 3.5, y: ground - 3.5))
            diamond.closeSubpath()
            map.fill(diamond, with: .color(Theme.fireGold.opacity(0.9)))
        }
        let kx = x(strip.king)
        map.fill(Path(CGRect(x: kx - 1, y: top + 3, width: 2, height: barHeight - 6)), with: .color(Theme.fireGold))
        var crown = Path()
        crown.move(to: CGPoint(x: kx - 5, y: top + 3))
        crown.addLine(to: CGPoint(x: kx + 5, y: top + 3))
        crown.addLine(to: CGPoint(x: kx, y: top + 9))
        crown.closeSubpath()
        map.fill(crown, with: .color(Theme.fireGold))
        context.stroke(outline, with: .color(Theme.gold.opacity(0.5)), lineWidth: 1)
        // M3: the petitioners waiting for the throne: a parchment bubble with their number over the great hall,
        // standing above the bar so the king's mark never hides it.
        if strip.petitioners > 0 {
            let hx = x(RealmStrip.hallPosition)
            let bubble = CGRect(x: hx - 8, y: max(0, top - 9), width: 16, height: 12)
            var tail = Path()
            tail.move(to: CGPoint(x: hx - 3, y: bubble.maxY - 0.5))
            tail.addLine(to: CGPoint(x: hx + 3, y: bubble.maxY - 0.5))
            tail.addLine(to: CGPoint(x: hx, y: bubble.maxY + 4))
            tail.closeSubpath()
            context.fill(Path(roundedRect: bubble, cornerRadius: 4), with: .color(Theme.parchment))
            context.fill(tail, with: .color(Theme.parchment))
            context.stroke(Path(roundedRect: bubble, cornerRadius: 4), with: .color(Theme.goldDeep), lineWidth: 1)
            context.draw(Text(verbatim: "\(strip.petitioners)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink), at: CGPoint(x: hx, y: bubble.midY))
        }
    }
}
