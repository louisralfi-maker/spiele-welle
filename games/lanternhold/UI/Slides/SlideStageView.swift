import SwiftUI
import UIKit

/// Where the slide stage stands over the world (the hook in `GameView`): nothing while no show is up; a show fades up
/// out of the dark and back into it. It also opens a show `-GWSlides` asks for.
@MainActor
struct SlideStageHost: View {
    let model: GameModel

    var body: some View {
        ZStack {
            // Always there (and never in the way), so the launch's show opens when the world first appears.
            Color.clear
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            if model.slides.isShowing {
                SlideStageView(model: model, stage: model.slides)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: model.reduceMotion ? 0.3 : 0.6), value: model.slides.isShowing)
        .onAppear { model.openSlidesFromLaunch() }
    }
}

/// LANTERN SLIDES (the director's idea, panels lane): each slide is a painted glass thrown on the dark by a lantern.
/// A dark surround; the lit gate with a warm vignette that breathes very slightly, soft dust in the beam and the picture
/// a little brighter at its centre. A tap pushes the old glass out sideways through the gate and the next one slides
/// in and settles, with a soft click. The words sit under the picture in the house's serif, two short lines at most; a
/// small "Skip" waits in the corner. Reduce Motion: cross-fades, no breathing, no drifting dust. It is the house's own
/// way of telling a story and no other game's.
@MainActor
struct SlideStageView: View {
    let model: GameModel
    let stage: SlideStage
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .title3) private var lineHeight: CGFloat = 26

    /// The slide whose words show under the picture (they follow the glass a moment later) and whether they show.
    @State private var wordsIndex = 0
    @State private var wordsShown = false

    private var reduceMotion: Bool { model.reduceMotion }

    var body: some View {
        ZStack {
            SlideSurround()
                .ignoresSafeArea()
            GeometryReader { geometry in
                let layout = SlideLayout(size: geometry.size, displayScale: displayScale, lineHeight: lineHeight)
                stageContent(layout)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            if stage.show?.skippable == true {
                skipButton
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("story-root")
        .task(id: stage.turn) {
            await showWords()
        }
    }

    // MARK: The stage

    @ViewBuilder
    private func stageContent(_ layout: SlideLayout) -> some View {
        let slide = stage.slide
        VStack(spacing: 0) {
            Spacer(minLength: layout.top)
            Button {
                model.turnSlide()
            } label: {
                VStack(spacing: layout.gap) {
                    gate(layout)
                    words(layout)
                    SlideProgress(count: stage.show?.slides.count ?? 0, index: stage.index,
                                  hint: wordsShown && !stage.isLast, reduceMotion: reduceMotion)
                        .frame(height: 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(SlideTapStyle())
            .accessibilityLabel(Text(verbatim: slide.map { words(of: $0).replacingOccurrences(of: "\n", with: " ") } ?? ""))
            .accessibilityValue(Text(verbatim: position))
            .accessibilityHint(Text(verbatim: SlideText.string(stage.isLast ? "slides.begin" : "slides.next",
                                                                lord: stage.lord)))
            .accessibilityIdentifier("story-next")
            Spacer(minLength: layout.bottom)
        }
    }

    /// The lit gate: the glass in it, the light over the glass, the label on the last slide's mount.
    private func gate(_ layout: SlideLayout) -> some View {
        let size = layout.picture
        return ZStack {
            // The spill of the lantern's light on the wall around the gate.
            SlideBeam(size: size, reduceMotion: reduceMotion)
                .allowsHitTesting(false)
            ZStack {
                Color(red: 0.03, green: 0.03, blue: 0.05)
                if let slide = stage.slide {
                    SlideGlass(image: SlidePictures.image(slide.picture.name(for: stage.lord.form)), size: size,
                               bar: layout.bar)
                        .id(stage.turn)
                        .transition(glassTransition(width: size.width + layout.bar))
                }
                SlideLight(size: size, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .mask(SlideGateMask(corner: layout.corner))
            .animation(glassAnimation, value: stage.turn)
            .accessibilityHidden(true)
        }
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .topLeading) {
            if let key = stage.slide?.labelKey {
                SlideLabel(text: SlideText.string(key, table: stage.slide?.table ?? SlideShow.table, lord: stage.lord))
                    .offset(x: -8, y: -9)
                    .opacity(wordsShown && wordsIndex == stage.index ? 1 : 0)
                    .accessibilityHidden(true)
            }
        }
    }

    /// The words under the picture: the house's roman in bone on the dark, two short lines at most.
    private func words(_ layout: SlideLayout) -> some View {
        let text = stage.show.flatMap { show in
            show.slides.indices.contains(wordsIndex) ? words(of: show.slides[wordsIndex]) : nil
        } ?? ""
        return Text(verbatim: text)
            .font(Theme.serif(.title3))
            .foregroundStyle(SlidePalette.words)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
            .frame(width: layout.wordsWidth, height: layout.words)
            .opacity(wordsShown ? 1 : 0)
            .accessibilityHidden(true)
    }

    private var skipButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    model.skipSlides()
                } label: {
                    HStack(spacing: 5) {
                        Text(verbatim: SlideText.string("slides.skip", lord: stage.lord))
                            .font(Theme.caps(.footnote))
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(SlidePalette.skip)
                    .padding(.horizontal, 14)
                    .frame(minWidth: 64, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SlideTapStyle())
                .accessibilityLabel(Text(verbatim: SlideText.string("slides.skip", lord: stage.lord)))
                .accessibilityIdentifier("story-skip")
            }
            Spacer()
        }
        .padding(.top, 4)
        .padding(.trailing, 6)
    }

    // MARK: Words and timing

    private func words(of slide: Slide) -> String {
        SlideText.string(slide.textKey, table: slide.table, lord: stage.lord)
    }

    private var position: String {
        let count = stage.show?.slides.count ?? 0
        let template = SlideText.string("slides.position", lord: stage.lord)
        return template
            .replacingOccurrences(of: "{n}", with: String(stage.index + 1))
            .replacingOccurrences(of: "{count}", with: String(count))
    }

    /// The old words go at once; the new ones fade in under the glass once it has come in.
    private func showWords() async {
        guard let slide = stage.slide else { return }
        if wordsShown {
            withAnimation(.easeIn(duration: 0.15)) { wordsShown = false }
        }
        let delay = max(0.16, reduceMotion ? 0.2 : slide.timing.textDelay)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        guard !Task.isCancelled else { return }
        wordsIndex = stage.index
        withAnimation(.easeOut(duration: reduceMotion ? 0.25 : 0.5)) { wordsShown = true }
    }

    // MARK: Motion

    /// The glass moves through the gate like a slide in a carrier: in from the right, out to the left, the dark bar of
    /// the carrier between them. Reduce Motion: a cross-fade.
    private func glassTransition(width: CGFloat) -> AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(insertion: .offset(x: width), removal: .offset(x: -width))
    }

    private var glassAnimation: Animation {
        if reduceMotion { return .easeInOut(duration: 0.35) }
        let settle = stage.slide?.timing.settle ?? SlideTiming.standard.settle
        return .spring(response: settle, dampingFraction: 0.84)
    }
}

/// The stage's measures: the picture as big as fits above two lines of words, at a whole number of device pixels per
/// painted pixel where that costs little.
struct SlideLayout: Equatable {
    var picture: CGSize
    var words: CGFloat
    var wordsWidth: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    var gap: CGFloat
    var bar: CGFloat
    var corner: CGFloat

    init(size: CGSize, displayScale: CGFloat, lineHeight: CGFloat) {
        let scale = max(1, displayScale)
        gap = 10
        top = 8
        bottom = 6
        words = ceil(lineHeight * 2 + 6)
        let progress: CGFloat = 14
        let maxHeight = max(80, size.height - top - bottom - words - progress - gap * 2)
        let maxWidth = max(160, size.width - 2 * 56)
        let pw = CGFloat(SlideShow.pictureWidth)
        let ph = CGFloat(SlideShow.pictureHeight)
        let ideal = min(maxHeight / ph, maxWidth / pw) * scale
        let whole = floor(ideal)
        // Crisp pixels when a whole number of device pixels per painted one keeps 85 % of the size or more.
        let device = whole >= 1 && whole >= ideal * 0.85 ? whole : ideal
        picture = CGSize(width: pw * device / scale, height: ph * device / scale)
        wordsWidth = min(size.width - 24, max(picture.width + 80, 600))
        bar = max(10, picture.width * 0.03)
        corner = max(6, picture.height * 0.035)
    }
}

/// The stage's few colours beyond the theme: the dark room, the lantern's warm light, the words in bone.
enum SlidePalette {
    static let room = Color(red: 0.027, green: 0.027, blue: 0.043)
    static let roomWarm = Color(red: 0.07, green: 0.05, blue: 0.04)
    static let lamp = Color(red: 1.0, green: 0.80, blue: 0.52)
    static let dust = Color(red: 1.0, green: 0.92, blue: 0.78)
    static let words = Theme.bone
    static let skip = Theme.boneDim
    static let lozenge = Theme.gold
}

/// The dark room the lantern throws its slides into.
struct SlideSurround: View {
    var body: some View {
        LinearGradient(colors: [SlidePalette.room, SlidePalette.roomWarm.opacity(0.9), SlidePalette.room],
                       startPoint: .top, endPoint: .bottom)
            .background(SlidePalette.room)
    }
}

/// The breathing used by the beam and the light (period 5.5 s, very slight).
private func breath(_ time: TimeInterval, phase: Double = 0) -> Double {
    sin((time / 5.5) * 2 * .pi + phase)
}

/// The lantern's light spilling onto the wall around the gate, a soft warm halo that breathes very slightly.
struct SlideBeam: View {
    let size: CGSize
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { context in
            let b = reduceMotion ? 0 : breath(context.date.timeIntervalSinceReferenceDate)
            EllipticalGradient(colors: [SlidePalette.lamp.opacity(0.20), SlidePalette.lamp.opacity(0.07), .clear],
                               center: .center, startRadiusFraction: 0.18, endRadiusFraction: 0.5)
                .frame(width: size.width * 1.55, height: size.height * 1.7)
                .opacity(0.88 + 0.12 * b)
        }
        .frame(width: size.width, height: size.height)
    }
}

/// One painted glass: the picture at whole pixels, with the carrier's dark bar on each side (outside the gate while
/// the slide rests).
struct SlideGlass: View {
    let image: UIImage?
    let size: CGSize
    let bar: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            SlidePalette.room.frame(width: bar)
            Group {
                if let image {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                } else {
                    Color(red: 0.08, green: 0.09, blue: 0.16)
                }
            }
            .frame(width: size.width, height: size.height)
            SlidePalette.room.frame(width: bar)
        }
        .frame(width: size.width + bar * 2, height: size.height)
    }
}

/// The light on the glass: brighter at the centre, a warm vignette at the edges that breathes very slightly, and dust
/// drifting in the beam. Reduce Motion: still light, still dust.
struct SlideLight: View {
    let size: CGSize
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = reduceMotion ? 12.0 : context.date.timeIntervalSinceReferenceDate
            let b = reduceMotion ? 0 : breath(time, phase: 1.1)
            ZStack {
                EllipticalGradient(colors: [SlidePalette.lamp.opacity(0.17 + 0.02 * b), .clear],
                                   center: .center, startRadiusFraction: 0, endRadiusFraction: 0.62)
                    .blendMode(.screen)
                EllipticalGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.52),
                    .init(color: Color(red: 0.16, green: 0.07, blue: 0.02).opacity(0.38 + 0.05 * b), location: 0.82),
                    .init(color: Color(red: 0.05, green: 0.02, blue: 0.01).opacity(0.78 + 0.05 * b), location: 1),
                ], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.72)
                SlideDust(time: time)
                    .blendMode(.plusLighter)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

/// Motes of dust caught in the beam in front of the glass: a few dozen soft points drifting up and across, brighter
/// at the centre of the light.
struct SlideDust: View {
    let time: TimeInterval
    static let count = 26

    var body: some View {
        Canvas { context, size in
            for n in 0..<SlideDust.count {
                let mote = Mote(n)
                let t = time.truncatingRemainder(dividingBy: 10_000)
                var x = mote.x + mote.vx * t + 0.012 * sin(t * mote.wobble + mote.phase)
                var y = mote.y + mote.vy * t
                x -= floor(x)
                y -= floor(y)
                let dx = x - 0.5
                let dy = (y - 0.5) * 0.8
                let lit = max(0, 1 - (dx * dx + dy * dy) * 3.2)
                let twinkle = 0.65 + 0.35 * sin(t * mote.twinkle + mote.phase * 2)
                let alpha = mote.alpha * lit * twinkle
                guard alpha > 0.02 else { continue }
                let r = mote.radius
                let rect = CGRect(x: x * size.width - r, y: y * size.height - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(SlidePalette.dust.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }

    /// One mote's fixed numbers, from its index (the same dust every time).
    struct Mote {
        var x, y, vx, vy, wobble, phase, twinkle, radius, alpha: Double

        init(_ n: Int) {
            var seed = UInt64(n) &* 0x9E37_79B9_7F4A_7C15 &+ 0x1234_5678
            func next() -> Double {
                seed ^= seed >> 30
                seed = seed &* 0xBF58_476D_1CE4_E5B9
                seed ^= seed >> 27
                seed = seed &* 0x94D0_49BB_1331_11EB
                seed ^= seed >> 31
                return Double(seed % 10_000) / 10_000
            }
            x = next()
            y = next()
            vx = (next() - 0.5) * 0.012
            vy = -(0.004 + next() * 0.010)
            wobble = 0.3 + next() * 0.6
            phase = next() * 6.28
            twinkle = 0.5 + next() * 1.5
            radius = 0.6 + next() * 1.3
            alpha = 0.18 + next() * 0.32
        }
    }
}

/// The gate's shape: the slide's mask with softly rounded corners and an edge a little out of focus.
struct SlideGateMask: View {
    let corner: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .padding(1.5)
            .blur(radius: 1.5)
    }
}

/// The paper label on the last slide's mount: the lord's name in the family book's hand.
struct SlideLabel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(Theme.italic(.subheadline))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(SlipBackground())
            .rotationEffect(.degrees(-2.5))
    }
}

/// The slides of the show as small lozenges under the words (the one showing in gold), and once the words are in, a
/// small gold chevron that breathes: tap to go on.
struct SlideProgress: View {
    let count: Int
    let index: Int
    let hint: Bool
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<count, id: \.self) { n in
                Rectangle()
                    .fill(n == index ? SlidePalette.lozenge : Theme.boneDim.opacity(n < index ? 0.55 : 0.25))
                    .frame(width: 6, height: 6)
                    .rotationEffect(.degrees(45))
            }
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion || !hint)) { context in
                let b = reduceMotion ? 1 : 0.5 + 0.5 * sin(context.date.timeIntervalSinceReferenceDate * 2.4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(SlidePalette.lozenge)
                    .opacity(hint ? 0.35 + 0.55 * b : 0)
            }
            .frame(width: 10)
        }
        .accessibilityHidden(true)
    }
}

/// Taps on the stage: pressing changes nothing (paper and glass lie still).
struct SlideTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
