import SwiftUI

/// The kit's pieces composed into one picture (stage-3-interface): every piece cut from the atlas at its place, on whole
/// game pixels; the last block is kept.
@MainActor
enum LanternKitImages {
    private static var last: (block: HUDKit.Block, image: CGImage)?

    static func image(_ block: HUDKit.Block) -> CGImage? {
        if let last, last.block == block { return last.image }
        guard block.width > 0 else { return nil }
        let rise = max(0, -(block.pieces.map(\.y).min() ?? 0))
        var canvas = PixelImage(width: block.width, height: block.height + rise)
        let layout = AtlasLayout.shared
        for piece in block.pieces {
            let cell = layout.cell(piece.sprite, frame: piece.frame)
            let pixels = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
            for y in 0..<pixels.height {
                for x in 0..<pixels.width {
                    let texel = pixels[x, y]
                    if texel.a > 0 { canvas[piece.x + x, piece.y + rise + y] = texel }
                }
            }
        }
        guard let made = SpriteImages.cgImage(canvas) else { return nil }
        last = (block, made)
        return made
    }

    /// One sprite frame at `points` per game px.
    static func sprite(_ sprite: SpriteID, frame: Int = 0) -> CGImage? {
        SpriteImages.image(sprite, frame: frame)
    }
}

/// The lantern moment (docs/HUD.md section 2; stage-3-interface): the lord has raised the house's lantern and the
/// world stands still under a light dim. Above him, on the world's pixel grid, the coin and the gold, the face of the
/// town's mood, the people and their count, and under them the day as the dawn sign and its number; at the top the
/// realm strip (a tap there walks him to that place); in the top right corner the gear to the pause sheet. Any other
/// touch lowers the lantern and the world runs on. No word stands on the world: VoiceOver reads the elements.
/// Build 3, lane 5 (no dead tap): the dim takes no finger; every other touch goes through `TouchLayer` to the model,
/// where a tap on a person or a thing lowers the lantern and does the deed in the same touch, a tap on the empty world
/// only lowers it, and a sideways drag looks around the still realm (`LookAround`). The strip and the gear keep
/// their own taps.
@MainActor
struct LanternMomentView: View {
    let model: GameModel
    let show: LanternMomentShow

    var body: some View {
        ZStack {
            world
            // The strip at the top and the gear in the corner keep inside the safe area (the display's corners).
            if let strip = model.strip {
                RealmStripView(strip: strip, reduceMotion: model.reduceMotion) { fraction in
                    model.travelFromLantern(toFraction: fraction)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            GearButton { model.openPauseFromLantern() }
                .padding(.top, 2)
                .padding(.trailing, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .accessibilityAction(.escape) { model.lowerLanternMoment() }
        .transition(model.reduceMotion ? .identity : .opacity)
    }

    /// The moment's element over the whole screen (it takes no finger: the touch goes through to the world; VoiceOver's
    /// double tap on it lowers the lantern) and the elements of the figures above the lord (the figures themselves are
    /// drawn in the world's frame, build 3). Build 3, lane 5 step 5: the flat black at 0.18 is gone; the dim is the
    /// lantern's own light, drawn by the renderer round the lord's glass (`LanternLight`).
    private var world: some View {
        GeometryReader { geometry in
            let perDevice = geometry.size.width / max(1, CGFloat(show.physicalWidth))
            let unit = CGFloat(show.scale) * perDevice
            let left = CGFloat(show.left) * perDevice
            let top = CGFloat(show.top) * perDevice
            let blockWidth = CGFloat(show.block.width) * unit
            ZStack(alignment: .topLeading) {
                Color.clear
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: show.summary))
                    .accessibilityHint(Text("Double tap to go on"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { model.lowerLanternMoment() }
                    .accessibilityIdentifier("lantern-moment")
                // Build 3, lane 5 step 4 (the step 2b critic's H1): the figures above the lord are drawn in Metal, in
                // the world's own frame (`GameModel.lanternWorld`), so they never trail the look-around's pan; only
                // their elements stand here, where the moment opened.
                figures(left: left, top: top, width: blockWidth, unit: unit)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }

    /// The elements over the block (they read the figures to VoiceOver and the UI tests): the gold on the row, the day
    /// under it. Build 3, lane 5 step 4: the row is the purse alone; the mood and the people are the town's banner's
    /// element at the strip (`hud-mood`).
    private func figures(left: CGFloat, top: CGFloat, width: CGFloat, unit: CGFloat) -> some View {
        let row = CGFloat(HUDKit.rowHeight) * unit
        return ZStack(alignment: .topLeading) {
            element("hud-gold", label: Text("Gold"), value: "\(show.gold)")
                .frame(width: max(1, width), height: row)
                .offset(x: left, y: top)
            Color.clear
                .frame(width: width, height: row)
                .accessibilityElement()
                .accessibilityLabel(Text("Day \(show.day)") + Text(verbatim: ", \(show.clock)"))
                .accessibilityIdentifier("hud-clock")
                .offset(x: left, y: top + row + CGFloat(HUDKit.lineGap) * unit)
        }
        .allowsHitTesting(false)
    }

    private func element(_ identifier: String, label: Text, value: String) -> some View {
        Color.clear
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(Text(verbatim: value))
            .accessibilityIdentifier(identifier)
    }
}

/// The gear (the interface kit's, 10 x 10 game px at 2 pt) on a small disc of the strip's glass (fix round 1, the
/// director's note of 15.11. 11:39: bare, it landed on the castle's flag), in a 48 pt touch area: it opens the pause
/// sheet.
struct GearButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                GearDisc()
                if let image = SpriteImages.image(.hudGear) {
                    Image(decorative: image, scale: 1 / NightGlass.pointsPerPixel)
                        .interpolation(.none)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 32, height: 32)
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pause"))
        .accessibilityIdentifier("hud-pause")
    }
}
