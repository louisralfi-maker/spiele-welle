import Observation
import SwiftUI

/// Build 3, lane 5 step 4 (decision 6, form C): the slip of the town's banner, one at a time. A touch on the banner
/// opens it with the main reason for the mood; a touch on the banner again, a touch anywhere else on the world
/// (`TouchLayer`), a tap on the strip, lowering the lantern or the strip going away closes it.
@MainActor
@Observable
final class MoodSlip {
    static let shared = MoodSlip()

    /// The slip's words while it stands, nil while it is shut.
    private(set) var text: String?

    func open(_ words: String) {
        text = words
    }

    func close() {
        if text != nil { text = nil }
    }

    /// A touch on the banner: it opens with `words`, or shuts if it stands.
    func toggle(_ words: String) {
        text = text == nil ? words : nil
    }
}

/// The banner's picture with the people beside it, composed from `Resources/Art/moodBanner.png` (tools/hudart.py; it
/// has no SpriteID: SwiftUI draws it, never the renderer) and the kit's people, figures and arrow from the atlas, on
/// whole game pixels; the last pictures are kept.
@MainActor
enum MoodBannerArt {
    private static var loaded: [PixelImage]?
    private static var cache: [String: CGImage] = [:]

    /// The banner's frames (empty without the PNG).
    static func frames() -> [PixelImage] {
        if let loaded { return loaded }
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: "moodBanner", withExtension: "png", subdirectory: "Art")
            ?? bundle.url(forResource: "moodBanner", withExtension: "png"),
            let image = PNGDecoder.load(url: url) else {
            loaded = []
            return []
        }
        let made = AtlasBuilder.splitFrames(image, size: MoodBanner.size, count: MoodBanner.frameCount)
        loaded = made
        return made
    }

    /// The banner in `frame` with the people group beside it (`MoodBanner.people`), in game px. Step 5b (the director's
    /// ruling M1 of 22.11.2026): each piece stands in the 1 px ink edge its atlas piece already has, as the lord's row
    /// does; nothing is drawn between the pieces, so the world may show there (no shared edge, no plate).
    static func pixels(frame: Int, people: HUDKit.Block) -> PixelImage? {
        let all = frames()
        guard frame >= 0, frame < all.count else { return nil }
        let size = MoodBanner.size
        var canvas = PixelImage(width: MoodBanner.peopleX + people.width, height: size.height)
        let banner = all[frame]
        for y in 0..<banner.height {
            for x in 0..<banner.width where banner[x, y].a > 0 {
                canvas[x, y] = banner[x, y]
            }
        }
        let layout = AtlasLayout.shared
        for piece in people.pieces {
            let cell = layout.cell(piece.sprite, frame: piece.frame)
            let texels = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
            for y in 0..<texels.height {
                for x in 0..<texels.width where texels[x, y].a > 0 {
                    canvas[MoodBanner.peopleX + piece.x + x, MoodBanner.peopleY + piece.y + y] = texels[x, y]
                }
            }
        }
        return canvas
    }

    static func image(frame: Int, people: Int, trend: Int) -> CGImage? {
        let key = "\(frame)#\(people)#\(trend)"
        if let hit = cache[key] { return hit }
        guard let canvas = pixels(frame: frame, people: MoodBanner.people(people, trend: trend)),
              let made = SpriteImages.cgImage(canvas) else { return nil }
        if cache.count > 32 { cache.removeAll() }
        cache[key] = made
        return made
    }
}

/// The town's banner under the realm strip's town end (build 3, lane 5 step 4; decision 6, form C): the cloth in the
/// mood's colour with the hood face, the people, their count and the trend beside it, each in its own ink edge. One
/// VoiceOver element (`hud-mood`: the mood, the people, the trend); a touch on it (a 44 pt target at least, below the
/// strip, clear of its tap and of the gear) opens the slip with the main reason under it (`hud-mood-slip`). No motion:
/// the cloth hangs still (no sway, so Reduce Motion needs no other form).
@MainActor
struct MoodBannerView: View {
    let strip: RealmStrip

    /// The banner's height in points (the strip's 2 pt a game px).
    static let height = CGFloat(MoodBanner.size.height) * RealmStripView.unit

    var body: some View {
        let unit = RealmStripView.unit
        let people = MoodBanner.people(strip.people, trend: strip.moodTrend)
        let width = CGFloat(MoodBanner.peopleX + people.width) * unit
        let words = MoodBannerView.reasonText(strip.moodReason, happiness: strip.happiness)
        let slip = MoodSlip.shared
        return ZStack(alignment: .topLeading) {
            Button {
                slip.toggle(words)
            } label: {
                Group {
                    if let image = MoodBannerArt.image(frame: MoodBanner.frame(happiness: strip.happiness),
                                                       people: strip.people, trend: strip.moodTrend) {
                        Image(decorative: image, scale: 1 / unit)
                            .interpolation(.none)
                    }
                }
                .frame(width: max(44, width), height: max(44, MoodBannerView.height), alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Mood of the town"))
            .accessibilityValue(Text(verbatim: MoodBannerView.voiceValue(strip)))
            .accessibilityHint(Text("Double tap for the reason"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("hud-mood")
            // The slip hangs under the cloth's middle.
            Color.clear
                .frame(width: CGFloat(MoodBanner.clothWidth) * unit, height: MoodBannerView.height)
                .overlay(alignment: .top) {
                    if let text = slip.text {
                        MoodSlipView(text: text)
                            .fixedSize()
                            .offset(y: MoodBannerView.height + 6)
                    }
                }
                .offset(x: CGFloat(MoodBanner.clothLeft) * unit)
                .allowsHitTesting(false)
        }
        .offset(x: CGFloat(MoodBanner.column) * unit)
        .onDisappear { slip.close() }
    }

    /// VoiceOver: "the town is grim, 14 people, the mood is falling".
    static func voiceValue(_ strip: RealmStrip) -> String {
        let mood = GameModel.moodWords(strip.happiness)
        var value = String(localized: "\(mood), \(strip.people) people")
        if strip.moodTrend > 0 { value += ", " + String(localized: "the mood is rising") }
        if strip.moodTrend < 0 { value += ", " + String(localized: "the mood is falling") }
        return value
    }

    /// The slip's words: the mood's main reason in plain words. Step 5 (the step-4 critic's M4, the director's words):
    /// with no change to name it names the mood itself, timeless, since the line can show on any day.
    static func reasonText(_ reason: MoodBanner.Reason, happiness: Int) -> String {
        switch reason {
        case .quiet:
            switch MoodBanner.mood(happiness: happiness) {
            case 0: return String(localized: "The town is in good heart.")
            case 1: return String(localized: "The town goes about its days.")
            case 2: return String(localized: "The town is weary.")
            default: return String(localized: "The town is angry.")
            }
        case .knocked: return String(localized: "You knocked at their doors.")
        case .dawn(let why):
            switch why {
            case .leftAlone: return String(localized: "You left their doors alone.")
            case .tavern: return String(localized: "The tavern keeps them merry.")
            case .chapel: return String(localized: "The Flame's blessing warms them.")
            case .noLosses: return String(localized: "No one fell in the night.")
            case .fallen: return String(localized: "They mourn the fallen.")
            case .unheard: return String(localized: "Petitioners went home unheard.")
            case .lowTax: return String(localized: "The tax is low.")
            case .normalTax: return String(localized: "The tax is fair.")
            case .highTax: return String(localized: "The tax is high.")
            case .warTax: return String(localized: "The war tax weighs on them.")
            }
        }
    }
}

/// The banner's slip: one line on night glass in the quiet hand, its pixel tail up to the cloth.
@MainActor
struct MoodSlipView: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Theme.italic(.subheadline))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(GlassPanelBackground())
            .overlay(alignment: .top) {
                GlassTail()
                    .rotationEffect(.degrees(180))
                    .offset(y: -4 * NightGlass.pointsPerPixel)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: text))
            .accessibilityIdentifier("hud-mood-slip")
    }
}
