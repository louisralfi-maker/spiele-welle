import SwiftUI
import UIKit

/// The first light (item 12 of the join; docs/TITLE.md, ci-out/director/first-light.md, the art of `claude/lh-title`
/// in Resources/Title): the launch, the loading and the title are one shot, and the light is the progress bar. On the
/// night's darkest colour the house's lantern catches (six steps; the first is heard and the beds come in), the
/// flame breathes while the game is made, its light uncovers the picture (polish C2: a stepped ellipse round the
/// eternal light, one calm swell of 1.6 s), the lettering lights from its centre outward, and a touch makes the lord on
/// the keep raise his lantern; the picture closes in on the flame and the hall rises out of the black (`StepIn`); then
/// the game (a new realm: the name entry, the prologue, day 1). Shown on a real launch only: a launch with any `-GW`
/// argument (every test) skips it unless `-GWTitle YES` asks for it.
enum TitleGate {
    static let shows: Bool = {
        if let asked = UserDefaults.standard.string(forKey: "GWTitle") { return AdMode.truthy(asked) }
        let arguments = ProcessInfo.processInfo.arguments.dropFirst()
        let environment = ProcessInfo.processInfo.environment
        let underTests = environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
        // A sweep's launch carries its plan in the environment and no argument (lh-rj-10 and lh-rj-15: the title
        // stood over every sweep shot until the runner gave up).
        let sweeping = environment[SweepPlan.environmentKey] != nil
        return !underTests && !sweeping && !arguments.contains { $0.hasPrefix("-GW") }
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
    /// The lord on the keep: feet (275, 88), sprite 9 x 16; his lantern is sprite column 0, row 11 / 7 / 3 / 1 (1a56dc7).
    static let lord = CGRect(x: 271, y: 73, width: 9, height: 16)
    static let lordLanternRow: [CGFloat] = [11, 7, 3, 1]
    /// His light (15 x 15) centred on his lantern's pixel.
    static let lordLightSize: CGFloat = 15
    /// The sentries (7 x 14), top left = feet - (3, 13).
    static let sentries: [(name: String, rect: CGRect)] = [
        ("titleSentryA", CGRect(x: 223, y: 119, width: 7, height: 14)),
        ("titleSentryB", CGRect(x: 321, y: 119, width: 7, height: 14)),
    ]
    // Polish C2: the reveal's numbers (116 to 340 game px over 1.6 s, its curve, the stepped mask) are `TitleTempo`'s
    // and `TitleMask`'s in Core/Motion.swift; the step into the game is `StepIn`'s.
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

/// The title's sounds (polish C2, F2; lane D built the sound side in steps 0b and D2, this only calls it). The beds
/// (`startTitleBeds`, the Throat's wind and the fire fading in over 1.5 s) start with the first lantern step, once,
/// and the lantern catching is heard once, on that step (`catchCue`); the touch plays `lanternUp` once (its soft 0.5
/// comes from the cue through the hub, behind the Haptics switch); the beds stop once at the black of the step into
/// the game (`StepIn.blackAt`), so the change of air falls into the cut. The switches hold before the game is on
/// screen: the hub is the model's, made with the saved Sound and Haptics before the first step.
@MainActor
final class TitleCues {
    /// The lantern catching: lantern.wav at 0.7, rate 1.1, no haptic, no place (the count's site lantern catching,
    /// the one cue that plays that file without a place; no cue of its own was added).
    static let catchCue = FeedbackCue.countLantern
    /// The title's touch: D2's lantern raise (lantern_up 0.42, soft 0.5).
    static let touchCue = FeedbackCue.lanternUp

    /// The model's hub, once the model is made (nil before: a step then waits for the next).
    var hub: (any FeedbackHub)?
    private(set) var bedsStarted = false
    private(set) var touchPlayed = false
    private(set) var bedsStopped = false

    init(hub: (any FeedbackHub)? = nil) {
        self.hub = hub
    }

    /// A lantern step of the loading: the first one that finds the hub starts the beds and plays the catch, once.
    func lanternStep() {
        guard !bedsStarted, let hub else { return }
        bedsStarted = true
        hub.startTitleBeds()
        hub.play(TitleCues.catchCue)
    }

    /// The touch that starts the game: the lantern raise, once.
    func touched() {
        guard !touchPlayed, let hub else { return }
        touchPlayed = true
        hub.play(TitleCues.touchCue)
    }

    /// The black of the step into the game: the beds stop, once (the game's air carries on from where they stand).
    func black() {
        guard !bedsStopped, let hub else { return }
        bedsStopped = true
        hub.stopTitleBeds()
    }
}

/// The title's mask (polish C2, M9): the open runs of `TitleMask` as whole game px rects, so the edge is stepped on the
/// picture's own grid. The rect is the picture's frame (520 x 201 game px at its scale).
struct TitleMaskShape: Shape {
    let radius: Int

    func path(in rect: CGRect) -> Path {
        let scale = rect.height / CGFloat(TitleMask.pictureHeight)
        var path = Path()
        for run in TitleMask.runs(radius: radius) {
            path.addRect(CGRect(x: rect.minX + CGFloat(run.from) * scale, y: rect.minY + CGFloat(run.y) * scale,
                                width: CGFloat(run.to - run.from) * scale, height: scale))
        }
        return path
    }
}

@MainActor
struct TitleView: View {
    /// The game is ready behind the light (the model is made); the lantern's last step waits for it.
    let ready: Bool
    /// The game's own Reduce Motion (`-GWReduceMotion`); the system's switch counts too.
    var reduceMotionArgument = false
    /// The title's sounds (made by the root, which hands it the model's hub).
    let cues: TitleCues
    /// The touch that starts the game, with its time (t = 0 of `StepIn`): the root raises the hall from it.
    let onStart: (Date) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var revealing = false
    /// Polish C2: when the reveal began and when the sixth step was reached (the breath's clock).
    @State private var revealAt: Date? = nil
    @State private var caughtAt: Date? = nil
    @State private var holdRadius: Int? = nil
    @State private var lit: Set<Int> = []
    @State private var started = false
    /// Polish C2: the touch that started the step into the game (t = 0 of `StepIn`).
    @State private var startedAt: Date? = nil
    /// Polish C2: a touch before the picture stands is kept and acts when the reveal ends.
    @State private var pendingTouch = false
    @State private var shown = Date()
    /// `ready` as state: the sequence's task holds the view value it started with, so it reads this live copy
    /// (lh-rj-9: reading `ready` there kept the lantern lit forever, the model was made after the task began).
    @State private var gameReady = false
    /// TITLE.md step 6: "Touch to begin" after 3 s without a touch.
    @State private var showHint = false
    /// The reveal has ended: the picture stands without its mask (the mask then opens every pixel already).
    @State private var revealDone = false

    /// `-GWTitleHold loading|half|lit|hint` (Debug only): the sequence holds at that state for the proof frames.
    private static let hold: String? = {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "GWTitleHold")?.lowercased()
        #else
        return nil
        #endif
    }()

    private var mode: MotionMode { MotionMode(reduceMotion: reduceMotion || reduceMotionArgument) }

    var body: some View {
        let mode = self.mode
        GeometryReader { geometry in
            let scale = geometry.size.height / TitleLayout.picture.height
            let left = (geometry.size.width - TitleLayout.windowWidth * scale) / 2 - TitleLayout.windowX * scale
            // Under Reduce Motion nothing moves until the step into the game, which fades by the clock.
            TimelineView(.animation(paused: mode.reduceMotion && startedAt == nil)) { timeline in
                let now = timeline.date
                let t = now.timeIntervalSince(shown)
                ZStack(alignment: .topLeading) {
                    if let startedAt {
                        stepIn(StepIn.picture(at: now.timeIntervalSince(startedAt), mode: mode), scale: scale, t: t)
                    } else if revealDone {
                        picture(scale: scale, t: t, lordFrame: 0)
                        lettering(scale: scale)
                    } else if revealing {
                        let radius = holdRadius ?? revealAt.map {
                            TitleTempo.revealRadius(at: now.timeIntervalSince($0), mode: mode)
                        } ?? TitleTempo.revealFrom
                        picture(scale: scale, t: t, lordFrame: 0)
                            .mask(alignment: .topLeading) { TitleMaskShape(radius: radius) }
                        lettering(scale: scale)
                    } else {
                        // The loading: the house's lantern catching, step by step, with its glow; while the game is
                        // still made the glow breathes between its steps 6 and 5 (polish C2, M9).
                        let shownStep = step < TitleTempo.catchSteps ? step
                            : TitleTempo.breathStep(since: caughtAt.map { now.timeIntervalSince($0) } ?? 0, mode: mode)
                        if shownStep > 0 {
                            sprite("lanternGlow\(shownStep)", CGRect(x: TitleLayout.windowX, y: 0,
                                                                    width: TitleLayout.windowWidth,
                                                                    height: TitleLayout.picture.height), scale)
                        }
                        sprite("lantern\(shownStep)", TitleLayout.beacon, scale)
                    }
                }
                .frame(width: TitleLayout.picture.width * scale, height: TitleLayout.picture.height * scale,
                       alignment: .topLeading)
                .background(startedAt == nil ? TitleLayout.night : Color.black)
                .offset(x: left)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
            .overlay(alignment: .bottom) {
                if showHint {
                    Text("Touch to begin")
                        .font(Theme.italic(.subheadline))
                        .foregroundStyle(NightGlass.bone.opacity(0.7))
                        .padding(.bottom, 18)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
        }
        // The step into the game goes to black (polish C2): the ground outside the closing mask is the game's black.
        .background(startedAt == nil ? TitleLayout.night : Color.black)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { touched() }
        .accessibilityElement()
        .accessibilityIdentifier("title-root")
        .accessibilityLabel(Text("Lanternhold"))
        .accessibilityHint(Text("Double tap to begin"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { touched() }
        .onAppear { gameReady = ready }
        .onChange(of: ready) { _, now in gameReady = now }
        .task { await run() }
    }

    // MARK: - The step into the game (polish C2, M8)

    /// One picture of `StepIn`'s timeline: the title closing on the flame (its lettering inside the same mask; the
    /// flame drawn over it unmasked, so it never blinks as the mask passes it), the flame alone, or black (the root's
    /// cover raises the hall over it).
    @ViewBuilder
    private func stepIn(_ shot: StepInPicture, scale: CGFloat, t: Double) -> some View {
        switch shot {
        case let .title(radius, lordFrame, opacity):
            if let radius {
                ZStack(alignment: .topLeading) {
                    picture(scale: scale, t: t, lordFrame: lordFrame)
                    lettering(scale: scale)
                }
                .mask(alignment: .topLeading) { TitleMaskShape(radius: radius) }
                flame(scale: scale, t: t)
            } else {
                ZStack(alignment: .topLeading) {
                    picture(scale: scale, t: t, lordFrame: lordFrame)
                    lettering(scale: scale)
                }
                .opacity(opacity)
            }
        case .flame:
            flame(scale: scale, t: t)
        case .black, .hall:
            EmptyView()
        }
    }

    /// The eternal light's flame (the picture's own sprite at its place, flickering as in the picture).
    private func flame(scale: CGFloat, t: Double) -> some View {
        sprite("lantern\(TitleView.flameStep(t: t, reduceMotion: mode.reduceMotion))", TitleLayout.beacon, scale)
    }

    /// The lantern's flicker on the title: 6 and 7 in irregular holds (0.18, 0.26, 0.12, 0.22 s).
    static func flameStep(t: Double, reduceMotion: Bool) -> Int {
        let cycle = t.truncatingRemainder(dividingBy: 0.78)
        return reduceMotion || cycle < 0.18 || (cycle >= 0.44 && cycle < 0.56) ? 6 : 7
    }

    // MARK: - The picture

    /// The layers in their order (first-light.md): sky, far, rock, castle, the lantern, the sentries, the lord's
    /// light, the lord, the parapet, the fog.
    private func picture(scale: CGFloat, t: Double, lordFrame: Int) -> some View {
        let still = mode.reduceMotion
        let sway = still ? 0 : sin(2 * Double.pi * t / 40)
        func drift(_ layer: String) -> CGFloat { ((TitleLayout.drift[layer] ?? 0) * CGFloat(sway)).rounded() }
        let full = CGRect(origin: .zero, size: TitleLayout.picture)
        let flame = TitleView.flameStep(t: t, reduceMotion: still)
        let breath: CGFloat = still ? 0 : (Int(t / 3) % 2 == 0 ? 0 : 1)
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
        // The lantern catches: six steps, 0.2 s each, the last waiting for the game. Polish C2 (F2): the first step is
        // heard, and the title's beds start with it.
        for next in 1...TitleTempo.catchSteps {
            try? await Task.sleep(nanoseconds: UInt64(TitleTempo.catchStepSeconds * 1_000_000_000))
            step = next
            cues.lanternStep()
            if TitleView.hold == "loading" && next == 3 { return }
        }
        caughtAt = Date()
        while !gameReady { try? await Task.sleep(nanoseconds: 50_000_000) }
        if TitleView.hold == "half" {
            holdRadius = (TitleTempo.revealFrom + TitleTempo.revealTo) / 2
            revealing = true
            return
        }
        await reveal()
        if TitleView.hold == "lit" { return }
        // TITLE.md step 6: after 3 s without a touch, the one small line.
        if TitleView.hold != "hint" { try? await Task.sleep(nanoseconds: 3_000_000_000) }
        if !started { withAnimation(.easeIn(duration: mode.reduceMotion ? 0 : 0.6)) { showHint = true } }
    }

    /// The reveal (polish C2, M9): one calm swell of 1.6 s with a stepped edge (`TitleTempo`, `TitleMask`); a touch
    /// kept from before acts as it ends; then the lettering lights. Reduce Motion: the picture stands at once.
    private func reveal() async {
        guard !revealing else { return }
        if mode.reduceMotion {
            revealing = true
            revealDone = true
            lit = Set(TitleLayout.letters.indices)
            if pendingTouch { begin() }
            return
        }
        revealAt = Date()
        revealing = true
        try? await Task.sleep(nanoseconds: UInt64(TitleTempo.revealSeconds * 1_000_000_000))
        revealDone = true
        if pendingTouch { begin() }
        for group in TitleLayout.lightOrder {
            lit.formUnion(group)
            try? await Task.sleep(nanoseconds: 70_000_000)
        }
    }

    /// A touch: once the picture stands the lord raises his lantern and the game begins; before (the loading, the
    /// reveal) it is kept and acts when the reveal ends (polish C2; before, a touch during the reveal cut the picture
    /// to its end and a second touch started, and one before the game was ready was lost).
    private func touched() {
        guard !started else { return }
        if revealDone { begin() } else { pendingTouch = true }
    }

    /// The step into the game begins (t = 0 of `StepIn`): the lantern raise is heard, the hint goes, the root takes it.
    private func begin() {
        guard !started else { return }
        started = true
        let at = Date()
        startedAt = at
        withAnimation(.lhLeave(.quick, mode: mode)) { showHint = false }
        cues.touched()
        onStart(at)
    }
}
