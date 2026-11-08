import SwiftUI

/// The App Store screenshots (DESIGN.md "Store shots"). With `-GWStoreShot <n>` the app draws shot n's headline on a
/// poster band above the live game screen, which is scaled down a little and framed like a phone. The whole picture is
/// one UI test screenshot (UITests/StoreShotsUITests.swift, 1320 x 2868 px on the iPhone 17 Pro Max), and the headline
/// is localised through the String Catalog like every other text. Nothing of it exists without that launch argument.
enum StoreShot: Int, CaseIterable, Sendable {
    case liftoff = 1
    case drop = 2
    case release = 3
    case goldRing = 4
    case hangar = 5

    /// About four words. The catalog's values, English included, carry the line break, so every language stands on two
    /// balanced lines.
    var headline: Text {
        switch self {
        case .liftoff: return Text("Launch your cargo rocket")
        case .drop: return Text("Drop each stage on time")
        case .release: return Text("Hit the glowing rings")
        case .goldRing: return Text("Fill rings, turn them gold")
        case .hangar: return Text("Upgrade and fly higher")
        }
    }
}

/// Shot n: the live screen on the poster. The live screen is laid out exactly as without the argument (same size, same
/// safe area), then drawn scaled down into its place under the headline band, with rounded corners, an ink rim and a
/// flat poster shadow. Scaling and moving are drawing effects only, so no layout inside the game changes. The layout needs
/// the whole screen and the live screen's layout frame (its safe area), both measured once the views are up.
struct StoreShotFrame<Content: View>: View {
    let shot: StoreShot
    let content: Content
    /// The whole screen, and the live screen's layout frame in screen points.
    @State private var screen: CGSize = .zero
    @State private var area: CGRect = .zero

    init(shot: StoreShot, @ViewBuilder content: () -> Content) {
        self.shot = shot
        self.content = content()
    }

    var body: some View {
        let layout = StoreShotLayout(screen: screen, area: area)
        let outline = StoreScreenOutline(insets: layout.insets, radius: StoreShotLayout.corner)
        content
            .clipShape(outline)
            .overlay {
                outline.stroke(Palette.ink, lineWidth: StoreShotLayout.rim)
            }
            .background {
                outline
                    .fill(Palette.ink.opacity(0.35))
                    .offset(y: StoreShotLayout.shadowDrop)
            }
            .scaleEffect(layout.scale, anchor: .topLeading)
            .offset(layout.offset)
            // Read after the drawing effects, so this is the untouched layout frame.
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                area = frame
            }
            // A background never changes the layout of the screen in front of it.
            .background {
                StoreShotPoster(shot: shot, layout: layout)
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { size in
                        screen = size
                    }
                    .ignoresSafeArea()
            }
    }
}

/// Where everything goes on the poster, from the whole screen and the live screen's layout frame (screen points). On the
/// 440 x 956 pt iPhone 17 Pro Max: a 172 pt band, the live screen at 0.80 (352 x 761 pt) centred under it.
struct StoreShotLayout: Equatable, Sendable {
    var screen: CGSize
    var area: CGRect

    /// The live screen's corner radius and ink rim in its own (unscaled) points, and the drop of its flat shadow.
    static let corner: CGFloat = 56
    static let rim: CGFloat = 9
    static let shadowDrop: CGFloat = 20
    /// Shares of the screen height: the headline band on top and the margin under the live screen.
    static let bandShare: CGFloat = 0.18
    static let marginShare: CGFloat = 0.024

    var isReady: Bool {
        screen.width > 0 && screen.height > 0 && area.width > 0 && area.height > 0
    }

    var band: CGFloat {
        (screen.height * Self.bandShare).rounded()
    }

    /// The live screen's scale: the height left under the band, less the margin under it.
    var scale: CGFloat {
        guard isReady else { return 1 }
        let margin = (screen.height * Self.marginShare).rounded()
        return (screen.height - band - margin) / screen.height
    }

    /// How far the live screen's picture reaches past its layout frame (the sky and the backgrounds reach under the
    /// status bar and the home indicator).
    var insets: EdgeInsets {
        guard isReady else { return EdgeInsets() }
        return EdgeInsets(top: area.minY, leading: area.minX, bottom: screen.height - area.maxY,
                          trailing: screen.width - area.maxX)
    }

    /// Scaled about the top-left corner of its layout frame, the screen's top-left corner lands at that corner times
    /// (1 - scale); this moves it to the middle under the band.
    var offset: CGSize {
        guard isReady else { return .zero }
        let shrink = 1 - scale
        let x = screen.width * shrink / 2 - area.minX * shrink
        let y = band - area.minY * shrink
        return CGSize(width: x, height: y)
    }

    /// The headline's box inside the band, and its type size (40 pt on the 440 pt wide screen).
    var captionWidth: CGFloat {
        max(0, screen.width - 56)
    }

    var fontSize: CGFloat {
        max(20, (screen.width * 0.091).rounded())
    }
}

/// The live screen's whole picture as a rounded rectangle: its layout frame grown by its safe-area insets.
struct StoreScreenOutline: Shape {
    var insets: EdgeInsets
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let whole = CGRect(x: rect.minX - insets.leading, y: rect.minY - insets.top,
                           width: rect.width + insets.leading + insets.trailing,
                           height: rect.height + insets.top + insets.bottom)
        return Path(roundedRect: whole, cornerRadius: radius, style: .continuous)
    }
}

/// The poster behind the live screen: a deep teal sky with paper grain, one mustard orbit ring passing behind the screen,
/// and the headline in heavy rounded paper type with a flat ink shadow and a mustard rule under it.
struct StoreShotPoster: View {
    let shot: StoreShot
    let layout: StoreShotLayout

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Palette.deepTeal, Palette.deepTealRGB.mix(Palette.navyRGB, 0.55).color],
                           startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                StoreShotDrawing.drawRing(context, size: size, layout: layout)
            }
            PaperGrain(opacity: 0.06)
                .equatable()
            VStack(spacing: 14) {
                shot.headline
                    .font(.rounded(layout.fontSize, .black))
                    .foregroundStyle(Palette.paper)
                    .shadow(color: Palette.ink.opacity(0.55), radius: 0, x: 0, y: 3)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .accessibilityIdentifier("store-caption")
                Capsule()
                    .fill(Palette.mustard)
                    .frame(width: 64, height: 7)
                    .accessibilityHidden(true)
            }
            .frame(width: layout.captionWidth, height: layout.band)
        }
    }
}

/// The poster's drawing, a plain enum so it carries no actor isolation.
enum StoreShotDrawing {
    /// One wide orbit ring around the live screen. It is drawn behind the screen, so only its arcs beside it show.
    static func drawRing(_ context: GraphicsContext, size: CGSize, layout: StoreShotLayout) {
        guard layout.isReady else { return }
        let height = layout.screen.height * layout.scale
        let centerY = layout.band + height * 0.58
        let rect = CGRect(x: -size.width * 0.12, y: centerY - size.width * 0.2, width: size.width * 1.24,
                          height: size.width * 0.4)
        let ring = Path(ellipseIn: rect)
        context.stroke(ring, with: .color(Palette.mustard.opacity(0.28)), lineWidth: 14)
        context.stroke(ring, with: .color(Palette.mustard.opacity(0.85)), lineWidth: 4)
        context.stroke(ring, with: .color(Palette.paper.opacity(0.9)), lineWidth: 1.5)
    }
}
