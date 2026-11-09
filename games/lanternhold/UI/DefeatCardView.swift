import Foundation
import SwiftUI

/// The defeat card (DESIGN.md "Losing a night", "The town": if the realm falls, the card shows the town's windows going
/// dark one by one; `defeat-root`, `defeat-second-chance`, `defeat-replay`): the second chance (the rewarded video of
/// M7; until then the button gives it at once, once per five nights) and "Replay the day" (back to this day's dawn).
@MainActor
struct DefeatCardView: View {
    let info: GameModel.DefeatInfo
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            // The background before the height limit: `.frame(maxHeight:)` takes all the height it is offered.
            CardScroll {
                content
            }
            .frame(width: min(460, geometry.size.width - 24))
            .background(NightBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("defeat-root")
    }

    private var content: some View {
        VStack(spacing: 12) {
            DarkeningTown()
                .frame(height: 60)
                .padding(.horizontal, 10)
            VStack(spacing: 4) {
                Text("The hearth has gone out")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Text("The Gloom reached the throne room on night \(info.night).")
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.parchment)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    model.takeSecondChance()
                } label: {
                    VStack(spacing: 2) {
                        Label("Second chance", systemImage: "flame.fill")
                        Text("The hearth flares up and dawn comes at once")
                            .font(Theme.serif(.footnote))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(info.secondChanceFrom != nil)
                .opacity(info.secondChanceFrom != nil ? 0.5 : 1)
                .accessibilityIdentifier("defeat-second-chance")
                if let from = info.secondChanceFrom {
                    Text("A second chance again from night \(from)")
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(Theme.moon)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    model.replayDay()
                } label: {
                    VStack(spacing: 2) {
                        Label("Replay the day", systemImage: "arrow.counterclockwise")
                        Text("Back to the morning of day \(info.replayDay)")
                            .font(Theme.serif(.footnote))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle(onDark: true))
                .accessibilityIdentifier("defeat-replay")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// The town's own cottages at night, their windows going dark one by one (DESIGN.md "The town"; M2b review: flat vector
/// houses read as placeholders beside the pixel art): the cottages and a big house cut from the renderer's atlas at whole
/// device pixels, tinted to the night, their window glass burning fireGold until it goes out, a window every 0.7 s from
/// the left (the side the Gloom came from).
struct DarkeningTown: View {
    static let step = 0.7

    struct Pane: Sendable {
        let dx: Int
        let dy: Int
        let width: Int
        let height: Int
    }

    struct House: Sendable {
        let sprite: SpriteID
        let flipped: Bool
        /// The window glass masks of EntityFrames.town (sprite pixels from the bottom-left, dy up), left to right.
        let panes: [Pane]
    }

    static let gap = 6
    static let houses: [House] = [
        House(sprite: .house, flipped: false, panes: [Pane(dx: 11, dy: 8, width: 5, height: 6),
                                                      Pane(dx: 46, dy: 8, width: 5, height: 6)]),
        House(sprite: .bigHouse, flipped: false, panes: [Pane(dx: 16, dy: 9, width: 5, height: 5),
                                                         Pane(dx: 26, dy: 24, width: 5, height: 5),
                                                         Pane(dx: 35, dy: 40, width: 3, height: 2),
                                                         Pane(dx: 41, dy: 24, width: 5, height: 5),
                                                         Pane(dx: 50, dy: 9, width: 5, height: 5)]),
        House(sprite: .houseC, flipped: true, panes: [Pane(dx: 11, dy: 8, width: 5, height: 6),
                                                      Pane(dx: 27, dy: 33, width: 3, height: 2),
                                                      Pane(dx: 46, dy: 8, width: 5, height: 6)]),
        House(sprite: .houseB, flipped: false, panes: [Pane(dx: 11, dy: 8, width: 5, height: 6),
                                                       Pane(dx: 46, dy: 8, width: 5, height: 6)]),
    ]

    /// The row's size in art pixels.
    static var artWidth: Int { houses.reduce(0) { $0 + $1.sprite.size.width } + gap * (houses.count - 1) }
    static var artHeight: Int { houses.map(\.sprite.size.height).max() ?? 1 }

    @State private var start = Date()
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let began = start
        let scale = displayScale
        let pictures = DarkeningTown.houses.map { SpriteImages.image($0.sprite) }
        let glass = DarkeningTown.houses.map { house in house.panes.map { DarkeningTown.glass(house, $0) } }
        return TimelineView(.periodic(from: began, by: DarkeningTown.step)) { context in
            let dark = max(0, Int(context.date.timeIntervalSince(began) / DarkeningTown.step))
            Canvas { graphics, size in
                DarkeningTown.draw(dark: dark, pictures: pictures, glass: glass, in: &graphics, size: size,
                                   displayScale: scale)
            }
        }
        .accessibilityHidden(true)
    }

    /// The glass of one window as a fireGold image (only the dark glass pixels inside the mask), cached.
    @MainActor private static var glassCache: [String: CGImage] = [:]

    @MainActor static func glass(_ house: House, _ pane: Pane) -> CGImage? {
        let key = "\(house.sprite.rawValue)#\(pane.dx),\(pane.dy)"
        if let hit = glassCache[key] { return hit }
        let layout = AtlasLayout.shared
        let cell = layout.cell(house.sprite, frame: 0)
        let top = house.sprite.size.height - pane.dy - pane.height
        var image = layout.image.cropped(x: cell.x + pane.dx, y: cell.y + top, width: pane.width, height: pane.height)
        let glassColours: Set<UInt32> = [0x0E0B1E, 0x1C1838, 0x2A2230]
        for y in 0..<image.height {
            for x in 0..<image.width {
                let c = image[x, y]
                let rgb = UInt32(c.r) << 16 | UInt32(c.g) << 8 | UInt32(c.b)
                image[x, y] = c.a > 127 && glassColours.contains(rgb) ? RGBA(0xFFC65A) : .clear
            }
        }
        guard let made = SpriteImages.cgImage(image) else { return nil }
        glassCache[key] = made
        return made
    }

    /// The row at whole device pixels per art pixel, bottom-aligned and centred; the first `dark` panes are out.
    static func draw(dark: Int, pictures: [CGImage?], glass: [[CGImage?]], in graphics: inout GraphicsContext,
                     size: CGSize, displayScale: CGFloat) {
        let fit = min(size.width * displayScale / CGFloat(artWidth), size.height * displayScale / CGFloat(artHeight))
        let pixel = max(1, fit.rounded(.down)) / displayScale
        let left = ((size.width - CGFloat(artWidth) * pixel) / 2 * displayScale).rounded(.down) / displayScale
        let base = size.height
        var x = left
        var window = 0
        for (index, house) in houses.enumerated() {
            let art = house.sprite.size
            let width = CGFloat(art.width) * pixel
            let height = CGFloat(art.height) * pixel
            let rect = CGRect(x: x, y: base - height, width: width, height: height)
            if index < pictures.count, let picture = pictures[index] {
                var night = graphics
                night.addFilter(.colorMultiply(Color(red: 0.36, green: 0.34, blue: 0.58)))
                if house.flipped {
                    night.translateBy(x: rect.midX, y: 0)
                    night.scaleBy(x: -1, y: 1)
                    night.translateBy(x: -rect.midX, y: 0)
                }
                night.draw(Image(decorative: picture, scale: 1).interpolation(.none), in: rect)
            }
            for (number, pane) in house.panes.enumerated() {
                let lit = window >= dark
                window += 1
                guard lit, index < glass.count, number < glass[index].count, let lamp = glass[index][number] else {
                    continue
                }
                let dx = house.flipped ? art.width - pane.dx - pane.width : pane.dx
                let paneRect = CGRect(x: x + CGFloat(dx) * pixel,
                                      y: base - CGFloat(pane.dy + pane.height) * pixel,
                                      width: CGFloat(pane.width) * pixel, height: CGFloat(pane.height) * pixel)
                graphics.fill(Path(ellipseIn: paneRect.insetBy(dx: -3 * pixel, dy: -3 * pixel)),
                              with: .color(Theme.fireGold.opacity(0.18)))
                var layer = graphics
                if house.flipped {
                    layer.translateBy(x: paneRect.midX, y: 0)
                    layer.scaleBy(x: -1, y: 1)
                    layer.translateBy(x: -paneRect.midX, y: 0)
                }
                layer.draw(Image(decorative: lamp, scale: 1).interpolation(.none), in: paneRect)
            }
            x += width + CGFloat(gap) * pixel
        }
    }
}

/// The pause sheet (DESIGN.md "Screens"; `pause-sheet`, `pause-resume`, `pause-sound`, `pause-haptics`,
/// `pause-restart`, `pause-restart-confirm`, `pause-restart-cancel`): resume, the sound and haptics switches (kept in
/// the save; sound and haptics play from M6), and restarting the chapter after a confirmation.
@MainActor
struct PauseSheetView: View {
    let model: GameModel
    @State private var confirming = false

    var body: some View {
        GeometryReader { geometry in
            CardScroll {
                content
            }
            .frame(width: min(420, geometry.size.width - 24))
            .background(NightBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-sheet")
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 12) {
            if confirming {
                Text("Restart chapter 1?")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Text("Your realm begins again on day 1. The Chronicle keeps its records.")
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                // M2b review: gold means "go on" everywhere else, so here it keeps the realm; the button that wipes it
                // is quiet with ember text and border.
                HStack(spacing: 10) {
                    Button {
                        confirming = false
                    } label: {
                        Text("Cancel").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .accessibilityIdentifier("pause-restart-cancel")
                    Button {
                        confirming = false
                        model.restartChapter()
                    } label: {
                        Text("Restart").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuietButtonStyle(onDark: true, danger: true))
                    .accessibilityIdentifier("pause-restart-confirm")
                }
            } else {
                Text("Paused")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Button {
                    model.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .accessibilityIdentifier("pause-resume")
                SettingRow(title: String(localized: "Sound"), isOn: model.settings.sound, identifier: "pause-sound") {
                    model.setSound(!model.settings.sound)
                }
                SettingRow(title: String(localized: "Haptics"), isOn: model.settings.haptics,
                           identifier: "pause-haptics") {
                    model.setHaptics(!model.settings.haptics)
                }
                Button {
                    confirming = true
                } label: {
                    Label("Restart chapter", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle(onDark: true))
                .accessibilityIdentifier("pause-restart")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// A switch row of the pause sheet: the whole row toggles (at least 48 pt high).
struct SettingRow: View {
    let title: String
    let isOn: Bool
    let identifier: String
    let toggle: @MainActor () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(verbatim: title)
                    .font(Theme.serif(.headline, .semibold))
                    .foregroundStyle(Theme.parchment)
                Spacer(minLength: 8)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Theme.gold : Theme.night0)
                        .frame(width: 48, height: 28)
                        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                    Circle()
                        .fill(Theme.parchment)
                        .frame(width: 22, height: 22)
                        .padding(3)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.night1.opacity(0.85)))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
        .accessibilityAddTraits(.isToggle)
        .accessibilityIdentifier(identifier)
    }
}
