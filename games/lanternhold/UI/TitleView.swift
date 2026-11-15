import SwiftUI
import UIKit

/// The first light (item 12 of the join; docs/TITLE.md, ci-out/director/first-light.md, the art of `claude/lh-title`
/// in Resources/Title): the launch, the loading and the title are one shot, and the light is the progress bar. On the
/// night's darkest colour the house's lantern catches (six steps), its light uncovers the picture (an ellipse round
/// the eternal light growing over 1.4 s), the lettering lights from its centre outward, and a touch makes the lord on
/// the keep raise his lantern; then the game (a new realm: the name entry, the prologue, day 1). Shown on a real launch
/// only: a launch with any `-GW` argument (every test) skips it unless `-GWTitle YES` asks for it.
enum TitleGate {
    static let shows: Bool = {
        if let asked = UserDefaults.standard.string(forKey: "GWTitle") { return AdMode.truthy(asked) }
        let arguments = ProcessInfo.processInfo.arguments.dropFirst()
        let environment = ProcessInfo.processInfo.environment
        let underTests = environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
        return !underTests && !arguments.contains { $0.hasPrefix("-GW") }
    }()
}

/// The title's numbers in game px of the 520 x 201 picture (Resources/Title/title.json, round 5 of first-light.md).
enum TitleLayout {
    static let picture = CGSize(width: 520, height: 201)
    /// The phone shows picture x 41 ... 477.
    static let windowX: CGFloat = 41
    static let windowWidth: CGFloat = 437
    /// The eternal light's flame; the reveal's ellipse is centred on it.
    static let flame = CGPoint(x: 259, y: 76)
    /// The house's lantern (`lantern0` ... `lantern7`, 13 x 18) on the beacon.
    static let beacon = CGRect(x: 253, y: 66, width: 13, height: 18)
    /// The lettering's box and each letter's box, L A N T E R N H O L D.
    static let lettering = CGRect(x: 143, y: 19, width: 232, height: 40)
    static let letters: [CGRect] = [
        CGRect(x: 143, y: 19, width: 18, height: 32), CGRect(x: 162, y: 19, width: 22, height: 32),
        CGRect(x: 185, y: 19, width: 21, height: 32), CGRect(x: 207, y: 19, width: 20, height: 32),
        CGRect(x: 228, y: 19, width: 18, height: 32), CGRect(x: 247, y: 19, width: 21, height: 32),
        CGRect(x: 269, y: 19, width: 21, height: 32), CGRect(x: 291, y: 19, width: 21, height: 32),
        CGRect(x: 313, y: 19, width: 21, height: 32), CGRect(x: 335, y: 19, width: 18, height: 32),
        CGRect(x: 354, y: 19, width: 21, height: 32),
    ]
    /// The order the letters light: R first, then outward in pairs (0.07 s apart).
    static let lightOrder: [[Int]] = [[5], [4, 6], [3, 7], [2, 8], [1, 9], [0, 10]]
    /// The lord on the keep: feet (275, 88), sprite 9 x 16; his lantern is sprite column 0, row 4 / 3 / 1 / 1.
    static let lord = CGRect(x: 271, y: 73, width: 9, height: 16)
    static let lordLanternRow: [CGFloat] = [4, 3, 1, 1]
    /// His light (15 x 15) centred on his lantern's pixel.
    static let lordLightSize: CGFloat = 15
    /// The sentries (7 x 14), top left = feet - (3, 13).
    static let sentries: [(name: String, rect: CGRect)] = [
        ("titleSentryA", CGRect(x: 223, y: 119, width: 7, height: 14)),
        ("titleSentryB", CGRect(x: 321, y: 119, width: 7, height: 14)),
    ]
    /// The reveal: R (long axis) from 116 to 260 game px over 1.4 s, the short axis × 120 / 170.
    static let revealFrom: CGFloat = 116
    static let revealTo: CGFloat = 260
    static let revealSeconds = 1.4
    static let shortAxis: CGFloat = 120.0 / 170.0
    /// The slow sway (game px at its peak, period 40 s): the castle and the light are the pivot.
    static let drift: [String: CGFloat] = ["sky": -3, "far": -2, "rock": -1, "castle": 0, "fog": 8]
    /// The launch's colour, the night's darkest (`#0A1124`).
    static let night = Color(red: 10 / 255, green: 17 / 255, blue: 36 / 255)
}

/// The title's PNGs, nearest neighbour, read once from Resources/Title.
@MainActor
final class TitleArt {
    static let shared = TitleArt()
    private var cache: [String: UIImage] = [:]

    func image(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Title")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
        guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache[name] = image
        return image
    }
}

@MainActor
struct TitleView: View {
    /// The game is ready behind the light (the model is made); the lantern's last step waits for it.
    let ready: Bool
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var revealing = false
    @State private var radius = TitleLayout.revealFrom
    @State private var lit: Set<Int> = []
    @State private var lordFrame = 0
    @State private var started = false
    @State private var shown = Date()
    /// `ready` as state: the sequence's task holds the view value it started with, so it reads this live copy
    /// (lh-rj-9: reading `ready` there kept the lantern lit forever, the model was made after the task began).
    @State private var gameReady = false

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.height / TitleLayout.picture.height
            let left = (geometry.size.width - TitleLayout.windowWidth * scale) / 2 - TitleLayout.windowX * scale
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSince(shown)
                ZStack(alignment: .topLeading) {
                    TitleLayout.night
                    if revealing {
                        picture(scale: scale, t: t)
                            .mask(alignment: .topLeading) {
                                Ellipse()
                                    .frame(width: 2 * radius * scale, height: 2 * radius * TitleLayout.shortAxis * scale)
                                    .offset(x: (TitleLayout.flame.x - radius) * scale,
                                            y: (TitleLayout.flame.y - radius * TitleLayout.shortAxis) * scale)
                            }
                        lettering(scale: scale)
                    } else {
                        // The loading: the house's lantern catching, step by step, with its glow.
                        if step > 0 {
                            sprite("lanternGlow\(step)", CGRect(x: TitleLayout.windowX, y: 0,
                                                               width: TitleLayout.windowWidth,
                                                               height: TitleLayout.picture.height), scale)
                        }
                        sprite("lantern\(step)", TitleLayout.beacon, scale)
                    }
                }
                .frame(width: TitleLayout.picture.width * scale, height: TitleLayout.picture.height * scale,
                       alignment: .topLeading)
                .offset(x: left)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
        }
        .background(TitleLayout.night)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { touched() }
        .accessibilityElement()
        .accessibilityIdentifier("title-root")
        .accessibilityLabel(Text("Lanternhold"))
        .accessibilityHint(Text("Touch to begin"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { touched() }
        .onAppear { gameReady = ready }
        .onChange(of: ready) { _, now in gameReady = now }
        .task { await run() }
    }

    // MARK: - The picture

    /// The layers in their order (first-light.md): sky, far, rock, castle, the lantern, the sentries, the lord's
    /// light, the lord, the parapet, the fog.
    private func picture(scale: CGFloat, t: Double) -> some View {
        let sway = reduceMotion ? 0 : sin(2 * Double.pi * t / 40)
        func drift(_ layer: String) -> CGFloat { ((TitleLayout.drift[layer] ?? 0) * CGFloat(sway)).rounded() }
        let full = CGRect(origin: .zero, size: TitleLayout.picture)
        // The lantern's flicker on the title: 6 and 7 in irregular holds (0.18, 0.26, 0.12, 0.22 s).
        let cycle = t.truncatingRemainder(dividingBy: 0.78)
        let flame = reduceMotion || cycle < 0.18 || (cycle >= 0.44 && cycle < 0.56) ? 6 : 7
        let breath: CGFloat = reduceMotion ? 0 : (Int(t / 3) % 2 == 0 ? 0 : 1)
        let lantern = CGPoint(x: TitleLayout.lord.minX, y: TitleLayout.lord.minY + TitleLayout.lordLanternRow[lordFrame])
        let light = CGRect(x: lantern.x - 7, y: lantern.y - 7, width: TitleLayout.lordLightSize,
                           height: TitleLayout.lordLightSize)
        return ZStack(alignment: .topLeading) {
            sprite("title1Sky", full.offsetBy(dx: drift("sky"), dy: 0), scale)
            sprite("title2Far", full.offsetBy(dx: drift("far"), dy: 0), scale)
            sprite("title3Rock", full.offsetBy(dx: drift("rock"), dy: 0), scale)
            sprite("title4Castle", full, scale)
            sprite("lantern\(flame)", TitleLayout.beacon, scale)
            ForEach(TitleLayout.sentries.indices, id: \.self) { index in
                sprite(TitleLayout.sentries[index].name, TitleLayout.sentries[index].rect, scale)
            }
            sprite("titleLordLight\(lordFrame)", light, scale)
            sprite("titleLord\(lordFrame)", TitleLayout.lord, scale)
            sprite("title4Parapet", full, scale)
            sprite("title5Fog", full.offsetBy(dx: drift("fog"), dy: breath), scale)
        }
    }

    /// The lettering, fixed to the screen: unlit, each letter's box swapped to the lit crop as it lights. The masks sit
    /// in the lettering's own frame, and the whole block is offset afterwards (lh-rj-11: masking an offset image put
    /// the masks at the picture's origin, so the wrong letters lit).
    private func lettering(scale: CGFloat) -> some View {
        let box = TitleLayout.lettering
        return ZStack(alignment: .topLeading) {
            plain("letteringUnlit", box.size, scale)
            ForEach(Array(lit).sorted(), id: \.self) { index in
                let letter = TitleLayout.letters[index]
                plain("letteringLit", box.size, scale)
                    .mask(alignment: .topLeading) {
                        Rectangle()
                            .frame(width: letter.width * scale, height: box.height * scale)
                            .padding(.leading, (letter.minX - box.minX) * scale)
                    }
            }
        }
        .frame(width: box.width * scale, height: box.height * scale, alignment: .topLeading)
        .offset(x: box.minX * scale, y: box.minY * scale)
    }

    /// One PNG at the origin of its frame, nearest neighbour.
    @ViewBuilder
    private func plain(_ name: String, _ size: CGSize, _ scale: CGFloat) -> some View {
        if let image = TitleArt.shared.image(name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .frame(width: size.width * scale, height: size.height * scale)
        }
    }

    /// One PNG at its place in game px, nearest neighbour.
    @ViewBuilder
    private func sprite(_ name: String, _ rect: CGRect, _ scale: CGFloat) -> some View {
        if let image = TitleArt.shared.image(name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .frame(width: rect.width * scale, height: rect.height * scale)
                .offset(x: rect.minX * scale, y: rect.minY * scale)
        }
    }

    // MARK: - The sequence

    private func run() async {
        shown = Date()
        // The lantern catches: six steps, at least 0.2 s each, the last waiting for the game.
        for next in 1...6 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            if revealing { return }
            step = next
        }
        while !gameReady { try? await Task.sleep(nanoseconds: 50_000_000) }
        await reveal()
    }

    private func reveal() async {
        guard !revealing else { return }
        revealing = true
        if reduceMotion {
            radius = TitleLayout.revealTo
            lit = Set(TitleLayout.letters.indices)
            return
        }
        withAnimation(.easeOut(duration: TitleLayout.revealSeconds)) { radius = TitleLayout.revealTo }
        try? await Task.sleep(nanoseconds: UInt64(TitleLayout.revealSeconds * 1_000_000_000))
        for group in TitleLayout.lightOrder {
            lit.formUnion(group)
            try? await Task.sleep(nanoseconds: 70_000_000)
        }
    }

    /// A touch: before the picture stands it skips ahead; once it stands the lord raises his lantern and the game
    /// begins.
    private func touched() {
        guard !started else { return }
        if !revealing || lit.count < TitleLayout.letters.count {
            guard gameReady else { return }
            revealing = true
            radius = TitleLayout.revealTo
            lit = Set(TitleLayout.letters.indices)
            return
        }
        started = true
        Task { @MainActor in
            for frame in 1...3 {
                lordFrame = frame
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            lordFrame = 2
            onStart()
        }
    }
}
