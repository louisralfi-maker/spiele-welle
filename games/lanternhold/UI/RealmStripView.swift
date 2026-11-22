import SwiftUI

/// Build 3, lane 5: the strip's picture, the last one kept. While the look-around slides the view the lantern moment is
/// drawn again every frame, and the strip's body with it (its tap is a closure, so SwiftUI cannot skip it); the picture
/// is made again only when the strip itself changed.
@MainActor
enum RealmStripImages {
    private static var last: (strip: RealmStrip, image: CGImage)?
    private static var lastTags: (tags: [RealmMapPixels.Tag], image: CGImage)?

    /// The strip without the calls' tags (step 5b: they are their own layer, `tags`).
    static func image(_ strip: RealmStrip) -> CGImage? {
        if let last, last.strip == strip { return last.image }
        guard let made = SpriteImages.cgImage(RealmMapPixels.image(strip, withTags: false)) else { return nil }
        last = (strip, made)
        return made
    }

    /// Build 3, lane 5 step 5b: the calls' tags alone (the red notes sign and its number), nil while nothing calls;
    /// kept while the tags stay the same (the view's bracket moving under a pan does not make it again).
    static func tags(_ strip: RealmStrip) -> CGImage? {
        let tags = RealmMapPixels.tags(strip)
        guard !tags.isEmpty else { return nil }
        if let lastTags, lastTags.tags == tags { return lastTags.image }
        guard let pixels = RealmMapPixels.tagsImage(strip), let made = SpriteImages.cgImage(pixels) else { return nil }
        lastTags = (tags, made)
        return made
    }
}

/// The realm strip (DESIGN.md "Controls"; docs/REVIEW-look-2.md H5, docs/HUD.md; rebuilt in stage-3-interface,
/// 15.11.2026): a map cut in pixels on night glass, 300 x 28 pt (150 x 14 game px at the world's 2 pt), the map's own
/// glyphs and never a letter (`RealmMapPixels`): the darkness bank, the Great Beacon, the walls by state, the
/// gatehouse, the keep, the postern, the roofs, the river, what is on screen, where the lord walks to, the lord's
/// lantern, the creatures at night, the Stranger, the hall's lit door while he is inside, and a call's ember tag with
/// the number of the waiting above it. It never stands on the walked world: it comes with the lantern moment and by
/// itself while something calls. A tap at a share of its map walks the lord to that share of the world
/// (`realm-strip`, 50 pt tall with the tag's room, so it is a 44 pt target).
struct RealmStripView: View {
    /// Points per game px of the strip (the world's on the iPhone 17 Pro).
    static let unit: CGFloat = 2
    static let height: CGFloat = CGFloat(RealmMapPixels.height) * unit
    static let width: CGFloat = CGFloat(RealmMapPixels.width) * unit

    let strip: RealmStrip
    let reduceMotion: Bool
    /// Build 3, lane 5 step 5 (the clean frame): how far the town's banner is faded while a finger holds the
    /// look-around's pan (`MomentFade`: 0 whole, 1 gone); the strip and its bracket never fade. Step 5b (the director's
    /// ruling of 22.11.2026): the calls' tags (the red notes sign) fade with it; they are a sign, not the map.
    let bannerClean: Double
    let onTap: @MainActor (Double) -> Void

    init(strip: RealmStrip, reduceMotion: Bool, bannerClean: Double = 0,
         onTap: @escaping @MainActor (Double) -> Void) {
        self.strip = strip
        self.reduceMotion = reduceMotion
        self.bannerClean = bannerClean
        self.onTap = onTap
    }

    var body: some View {
        let snapshot = strip
        let image = RealmStripImages.image(snapshot)
        // Build 3, lane 5 step 4 (decision 6, form C): the town's banner hangs under the strip's town end, wherever
        // the strip shows (the lantern moment, a call); the strip's own tap and element stay the map's. It hangs in an
        // overlay, so the strip keeps its own frame and nothing under it (the horn's ribbon in a call) moves down.
        return ZStack {
            if let image {
                Image(decorative: image, scale: 1 / RealmStripView.unit)
                    .interpolation(.none)
                    .frame(width: RealmStripView.width, height: RealmStripView.height)
            }
            // Step 5b: the calls' tags over the strip in their own layer, faded with the banner and gone at 1. They
            // were never their own touch or element (a tap on them is the strip's, the strip's value reads the
            // waiting to VoiceOver), so nothing else changes: with VoiceOver `bannerClean` stays 0, and under Reduce
            // Motion it jumps (`LanternVeil`).
            if bannerClean < 1, let tags = RealmStripImages.tags(snapshot) {
                Image(decorative: tags, scale: 1 / RealmStripView.unit)
                    .interpolation(.none)
                    .frame(width: RealmStripView.width, height: RealmStripView.height)
                    .opacity(1 - bannerClean)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: RealmStripView.width, height: RealmStripView.height)
        .contentShape(Rectangle())
        .onTapGesture { location in
            MoodSlip.shared.close()
            onTap(RealmMapPixels.fraction(column: Double(location.x / RealmStripView.unit)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Map of the valley"))
        .accessibilityValue(Text(verbatim: RealmStripView.callsValue(snapshot)))
        .accessibilityHint(Text("Tap to walk there"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("realm-strip")
        .overlay(alignment: .topLeading) {
            // Step 5 (the clean frame): wholly faded, the banner leaves the view, so no touch and no accessibility
            // element (not even a UI test's) finds it; while it fades it takes no touch and is hidden from VoiceOver.
            if bannerClean < 1 {
                MoodBannerView(strip: snapshot)
                    .frame(width: RealmStripView.width, height: MoodBannerView.height, alignment: .topLeading)
                    .opacity(1 - bannerClean)
                    .allowsHitTesting(bannerClean == 0)
                    .accessibilityHidden(bannerClean > 0)
                    .offset(y: RealmStripView.height)
            }
        }
    }

    /// The strip's VoiceOver value: who waits, and (fix lane D, player-loop-1) how many of the town's doors still owe
    /// today, so the pointer to the taxes reaches VoiceOver too; empty while nothing calls.
    static func callsValue(_ strip: RealmStrip) -> String {
        var parts: [String] = []
        if strip.petitioners > 0 { parts.append(String(localized: "Petitioners waiting: \(strip.petitioners)")) }
        if strip.owingDoors > 0 { parts.append(String(localized: "Doors owing: \(strip.owingDoors)")) }
        return parts.joined(separator: ", ")
    }
}
