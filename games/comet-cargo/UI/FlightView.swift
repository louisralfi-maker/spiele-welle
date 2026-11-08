import SwiftUI

/// The flight screen: the Canvas scene, the HUD and the pause card. A touch anywhere outside the buttons ignites on the
/// pad and drops the current stage in flight. Every timing input fires when the finger touches down, not when it lifts,
/// so how long the finger rests never shifts a rating.
struct FlightView: View {
    let driver: FlightDriver
    let model: GameModel
    /// The bottom of the HUD's top bar and the top of the scene, both in the flight screen's own coordinate space
    /// (`FlightSpace`), so their difference is the bar's bottom in scene points even while a store shot draws the whole
    /// screen scaled down. The scene keeps its apex and ring plates below it. 132 pt until measured.
    @State private var barBottom: CGFloat = 132
    @State private var sceneTop: CGFloat = 0

    var body: some View {
        ZStack {
            FlightSceneView(driver: driver, hudBottom: barBottom - sceneTop)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .named(FlightSpace.name)).minY
                } action: { top in
                    if abs(top - sceneTop) > 0.5 { sceneTop = top }
                }
                .ignoresSafeArea()
            PaperGrain(opacity: 0.035)
                .equatable()
                .ignoresSafeArea()
            FlightHUD(driver: driver, onTopBarBottom: { bottom in
                if abs(bottom - barBottom) > 0.5 { barBottom = bottom }
            })
            if driver.paused {
                PauseCard(onResume: { driver.resume() }, onAbort: { model.abortFlight() })
                    .transition(.opacity)
            }
        }
        .coordinateSpace(.named(FlightSpace.name))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("flight-root")
    }
}

/// The flight screen's own coordinate space. Measured in it, the HUD bar and the scene keep their distance whatever is
/// drawn around the screen (a store shot scales the whole screen down, which changes every global frame).
enum FlightSpace {
    static let name = "flight-screen"
}

/// The part that redraws every frame. It is also the big "tap anywhere" control: VoiceOver reads it as a button
/// ("Launch" on the pad, then "Drop stage") with an action, since a tap on the screen is the only other way to do that.
struct FlightSceneView: View {
    let driver: FlightDriver
    var hudBottom: CGFloat = 132
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(driver: FlightDriver, hudBottom: CGFloat = 132) {
        self.driver = driver
        self.hudBottom = hudBottom
    }

    var body: some View {
        let state = driver.sceneState(reduceMotion: reduceMotion, hudBottom: hudBottom)
        let onPad = state.phase == .pad
        let shake = reduceMotion ? ShakeOffset.still : FlightShake.offset(
            sinceIgnition: driver.clock - driver.ignitedAt,
            sinceDrop: driver.clock - driver.droppedAt
        )
        Canvas { context, size in
            FlightScene.draw(&context, size: size, state: state)
        }
        .scaleEffect(shake.scale)
        .offset(x: shake.x, y: shake.y)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 10_000, perform: {}, onPressingChanged: { pressing in
            if pressing { driver.tapScene() }
        })
        .accessibilityElement()
        .accessibilityLabel(onPad ? Text("Launch") : Text("Drop stage"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { driver.tapScene() }
        .accessibilityIdentifier("flight-scene")
    }
}

/// One frame of the screen shake: an offset, and a zoom just big enough that the shaken scene never shows its edges.
struct ShakeOffset: Sendable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat

    static let still = ShakeOffset(x: 0, y: 0, scale: 1)
}

/// A tiny shake of the scene on ignition (4 pt, 0.45 s) and on every stage drop (3 pt, 0.25 s), decaying to nothing.
/// None under Reduce Motion (the caller skips it).
enum FlightShake {
    static let igniteTime = 0.45
    static let igniteAmplitude = 4.0
    static let dropTime = 0.25
    static let dropAmplitude = 3.0

    /// The strongest shake running now, by age; 0 when none.
    static func amplitude(sinceIgnition: Double, sinceDrop: Double) -> (amplitude: Double, age: Double) {
        var amplitude = 0.0
        var age = 0.0
        if sinceIgnition >= 0 && sinceIgnition < igniteTime {
            amplitude = igniteAmplitude * (1 - sinceIgnition / igniteTime)
            age = sinceIgnition
        }
        if sinceDrop >= 0 && sinceDrop < dropTime {
            let drop = dropAmplitude * (1 - sinceDrop / dropTime)
            if drop > amplitude {
                amplitude = drop
                age = sinceDrop
            }
        }
        return (amplitude, age)
    }

    static func offset(sinceIgnition: Double, sinceDrop: Double) -> ShakeOffset {
        let now = amplitude(sinceIgnition: sinceIgnition, sinceDrop: sinceDrop)
        guard now.amplitude > 0 else { return .still }
        let x = now.amplitude * sin(now.age * 61)
        let y = now.amplitude * 0.6 * sin(now.age * 47 + 1.3)
        // 2 × amplitude over a 360 pt side: at least the amplitude of overscan on every edge of a phone screen.
        let zoom = 1 + 2 * now.amplitude / 360
        return ShakeOffset(x: CGFloat(x), y: CGFloat(y), scale: CGFloat(zoom))
    }
}

/// How the rocket sits relative to a ring right now, for the release button.
enum BandCue: Sendable, Equatable {
    case outside
    case inside
    case perfect
}

struct FlightHUD: View {
    let driver: FlightDriver
    /// Reports where the top bar ends (in `FlightSpace`), for the scene's labels.
    let onTopBarBottom: (CGFloat) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(driver: FlightDriver, onTopBarBottom: @escaping (CGFloat) -> Void = { _ in }) {
        self.driver = driver
        self.onTopBarBottom = onTopBarBottom
    }

    var body: some View {
        GeometryReader { geo in
            let sim = driver.sim
            let clock = driver.clock
            ZStack {
                VStack(spacing: 0) {
                    topBar(sim)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .named(FlightSpace.name)).maxY
                        } action: { bottom in
                            onTopBarBottom(bottom)
                        }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        releaseButton(sim, clock: clock)
                            .overlay(alignment: .topLeading) {
                                if driver.hint == .release {
                                    ReleaseHint(clock: clock, reduceMotion: reduceMotion)
                                        .offset(x: 56, y: 56)
                                }
                            }
                    }
                }
                HStack {
                    TankGauge(
                        fraction: sim.phase == .pad ? 1 : sim.fuelFraction,
                        cue: sim.gaugeCue,
                        zones: Ratings.gaugeZones(guidance: sim.rocket.guidance),
                        clock: clock,
                        refusedAge: clock - driver.refusedAt,
                        stageCount: sim.stageCount,
                        stageIndex: sim.stageIndex,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: geo.size.height * 0.4 + 60)
                    .padding(.leading, 10)
                    Spacer()
                }
                .allowsHitTesting(false)
                // "Tap to launch" in the empty sky above the rocket (the nose stands at about 0.55 h), never over the
                // rocket. The fixed width (65 pt clear on each side) keeps a long translation off the gauge and the
                // edge; the capsule hugs its text and stays centred.
                if sim.phase == .pad && !driver.autoplay {
                    launchPrompt(clock)
                        .frame(width: max(120, geo.size.width - 130))
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.36)
                        .allowsHitTesting(false)
                }
                if driver.hint == .drop {
                    // Centred left of 0.72 w on narrow phones, so the pulsing bubble keeps clear of the right edge.
                    DropHint(clock: clock, reduceMotion: reduceMotion)
                        .position(x: min(geo.size.width * 0.68, geo.size.width - 112), y: geo.size.height * 0.46)
                }
            }
        }
    }

    /// "Tap to launch" on the pad; during the first flights with a tapping hand beside it.
    @ViewBuilder
    private func launchPrompt(_ clock: Double) -> some View {
        if driver.hint == .launch {
            LaunchHint(clock: clock, reduceMotion: reduceMotion, opacity: launchPulse(clock))
        } else {
            TapToLaunch(opacity: launchPulse(clock))
        }
    }

    private func topBar(_ sim: FlightSim) -> some View {
        ZStack {
            HStack {
                PauseButton(driver: driver)
                Spacer()
                CoinPill(value: driver.flightCoins)
                    .padding(.trailing, 8)
            }
            AltitudeReadout(
                km: Int(sim.altitude.rounded()),
                tenths: Int((max(0, sim.speed) * 10).rounded()),
                fastForward: driver.fastForward
            )
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private func releaseButton(_ sim: FlightSim, clock: Double) -> some View {
        let band = bandCue(sim)
        var scale: CGFloat = 1
        if band != .outside && !reduceMotion {
            scale = CGFloat(1.05 + 0.04 * sin(clock * 14))
        }
        return ReleaseButton(
            count: sim.satellitesAboard,
            enabled: sim.isFlying && sim.satellitesAboard > 0,
            band: band,
            scale: scale,
            driver: driver
        )
    }

    private func bandCue(_ sim: FlightSim) -> BandCue {
        guard let band = sim.liveBand else { return .outside }
        return band.rating == .perfect ? .perfect : .inside
    }

    private func launchPulse(_ clock: Double) -> Double {
        reduceMotion ? 1 : 0.6 + 0.4 * abs(sin(clock * 2.6))
    }
}

/// "Tap to launch" on a paper capsule. The capsule hugs its text; within a narrower proposal (the HUD gives it the width
/// between the gauge and the right edge) a long translation shrinks to as little as 60 % on one line instead of
/// reaching the gauge or the edge.
struct TapToLaunch: View {
    let opacity: Double

    var body: some View {
        Text("Tap to launch")
            .font(.rounded(28, .black))
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Capsule().fill(Palette.paper.opacity(0.85)))
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

// MARK: First-flight hints

/// The timing of the hint hand: it taps about 1.4 times a second (down, a short hold, up, a rest) and a ring spreads
/// from the fingertip at each touch. Under Reduce Motion it rests (phase 0).
enum HintMotion {
    static let tapsPerSecond = 1.4

    static func phase(clock: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 0 }
        let raw = (clock * tapsPerSecond).truncatingRemainder(dividingBy: 1)
        return raw < 0 ? raw + 1 : raw
    }

    /// 0 up, 1 pressed down.
    static func press(_ phase: Double) -> Double {
        if phase < 0.22 { return ease(phase / 0.22) }
        if phase < 0.4 { return 1 }
        if phase < 0.7 { return 1 - ease((phase - 0.4) / 0.3) }
        return 0
    }

    /// The ring from the fingertip: 0 before the touch, then 0 → 1 as it spreads and fades.
    static func ripple(_ phase: Double) -> Double {
        guard phase >= 0.22 else { return 0 }
        return min(1, (phase - 0.22) / 0.5)
    }

    static func ease(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }
}

/// A pointing hand that taps with its fingertip at its top-left corner, and a mustard ring spreading from the touch.
struct HintHand: View {
    let clock: Double
    let reduceMotion: Bool
    var size: CGFloat = 60

    init(clock: Double, reduceMotion: Bool, size: CGFloat = 60) {
        self.clock = clock
        self.reduceMotion = reduceMotion
        self.size = size
    }

    var body: some View {
        let phase = HintMotion.phase(clock: clock, reduceMotion: reduceMotion)
        let press = CGFloat(HintMotion.press(phase))
        let ripple = HintMotion.ripple(phase)
        ZStack(alignment: .topLeading) {
            Circle()
                .stroke(Palette.mustard, lineWidth: 3)
                .frame(width: size * 0.5, height: size * 0.5)
                .scaleEffect(CGFloat(0.4 + 1.2 * ripple))
                .opacity(ripple > 0 ? 1 - ripple : 0)
                .offset(x: -size * 0.18, y: -size * 0.2)
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(Palette.paper)
                .shadow(color: Palette.ink.opacity(0.6), radius: 0, x: 2, y: 3)
                .scaleEffect(1 - 0.08 * press, anchor: .topLeading)
                .offset(x: 8 * (1 - press), y: 8 * (1 - press))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// On the pad during the first flights: "Tap to launch" with the hand tapping its lower right corner.
struct LaunchHint: View {
    let clock: Double
    let reduceMotion: Bool
    let opacity: Double

    var body: some View {
        TapToLaunch(opacity: max(0.85, opacity))
            .overlay(alignment: .bottomTrailing) {
                HintHand(clock: clock, reduceMotion: reduceMotion, size: 56)
                    .offset(x: 22, y: 52)
            }
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Tap to launch"))
            .accessibilityIdentifier("hint-launch")
    }
}

/// The first stage's fuel is in the Perfect zone (the flight runs in slow motion): a pulsing "Tap now!" and the hand
/// tapping over the scene.
struct DropHint: View {
    let clock: Double
    let reduceMotion: Bool

    var body: some View {
        let pulse = reduceMotion ? 1.0 : 1 + 0.08 * abs(sin(clock * 8))
        VStack(spacing: 4) {
            Text("Tap now!")
                .font(.rounded(26, .black))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Palette.mustard))
                .overlay(Capsule().stroke(Palette.paper, lineWidth: 2))
                .scaleEffect(CGFloat(pulse))
            HintHand(clock: clock, reduceMotion: reduceMotion, size: 64)
                .offset(x: 14)
        }
        .frame(maxWidth: 190)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tap now!"))
        .accessibilityIdentifier("hint-drop")
    }
}

/// The first ring entered with a satellite aboard (slow motion): the hand taps the release button.
struct ReleaseHint: View {
    let clock: Double
    let reduceMotion: Bool

    var body: some View {
        HintHand(clock: clock, reduceMotion: reduceMotion, size: 58)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Release now"))
            .accessibilityIdentifier("hint-release")
    }
}

/// Altitude and speed on a dark capsule, readable over clouds and over space. Only plain values, so SwiftUI skips it
/// while the numbers stay the same.
struct AltitudeReadout: View {
    let km: Int
    let tenths: Int
    let fastForward: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("\(km) km")
                .font(.rounded(34, .black).monospacedDigit())
                .foregroundStyle(Palette.paper)
                .shadow(color: Palette.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .accessibilityIdentifier("flight-altitude")
            HStack(spacing: 6) {
                Text(verbatim: "\((Double(tenths) / 10).formatted(.number.precision(.fractionLength(1)))) km/s")
                    .font(.rounded(14, .bold).monospacedDigit())
                    .foregroundStyle(Palette.paper)
                if fastForward {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Palette.mustard)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Capsule().fill(Palette.night.opacity(0.35)))
    }
}

struct CoinPill: View {
    let value: Int

    var body: some View {
        CoinAmount(value: value, size: 20, color: Palette.paper)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.deepTeal.opacity(0.85)))
            .overlay(Capsule().stroke(Palette.paper.opacity(0.5), lineWidth: 1.5))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(value) coins"))
    }
}

/// The pause button: a 44 pt circle inside a 60 pt square that catches near misses, so they never drop a stage.
struct PauseButton: View {
    let driver: FlightDriver

    var body: some View {
        Button {
            Feedback.shared.play(.button)
            driver.pause()
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Palette.paper)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Palette.deepTeal.opacity(0.85)))
                .overlay(Circle().stroke(Palette.paper.opacity(0.5), lineWidth: 1.5))
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Pause"))
        .accessibilityIdentifier("flight-pause")
    }
}

/// The tank of the burning stage. The fuel is a warm orange column that drains; the zones (Perfect at the bottom in
/// mustard, Great in teal, Good in paper) show along both edges and as a ruler on the right. In the Perfect window the
/// gauge glows and pulses; once the stage is burnt out it blinks mustard and coral through the grace time, then coral.
/// On the last stage the zones disappear (there is nothing to drop). Shakes when a drop is refused.
struct TankGauge: View {
    let fraction: Double
    let cue: GaugeCue
    let zones: (perfect: Double, great: Double, good: Double)
    let clock: Double
    let refusedAge: Double
    let stageCount: Int
    let stageIndex: Int
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                TankGaugeDrawing.draw(context, size: size, fraction: fraction, cue: cue, zones: zones, clock: clock,
                                      reduceMotion: reduceMotion)
            }
            .frame(width: 52)
            StagePips(count: stageCount, index: stageIndex)
        }
        .offset(x: shakeOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Fuel"))
        .accessibilityValue(Text(verbatim: "\(Int((min(1, max(0, fraction)) * 100).rounded())) %"))
    }

    private var shakeOffset: CGFloat {
        guard !reduceMotion, refusedAge >= 0, refusedAge < 0.35 else { return 0 }
        let decay = 1 - refusedAge / 0.35
        return CGFloat(sin(refusedAge * 70) * 7 * decay)
    }
}

/// One pip per stage, the burning one ringed in mustard.
struct StagePips: View {
    let count: Int
    let index: Int

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<max(0, count), id: \.self) { row in
                let stage = count - 1 - row
                Circle()
                    .fill(stage >= index ? Palette.paper : Palette.paper.opacity(0.15))
                    .overlay(Circle().stroke(stage == index ? Palette.mustard : Palette.ink.opacity(0.4), lineWidth: 2))
                    .frame(width: 11, height: 11)
            }
        }
        .padding(.trailing, 10)
    }
}

/// The gauge drawing, a plain enum so it carries no actor isolation.
enum TankGaugeDrawing {
    static func draw(_ context: GraphicsContext, size: CGSize, fraction: Double, cue: GaugeCue,
                     zones: (perfect: Double, great: Double, good: Double), clock: Double, reduceMotion: Bool) {
        let track = CGRect(x: 6, y: 6, width: 30, height: max(10, size.height - 12))
        let shape = Path(roundedRect: track, cornerRadius: track.width / 2)
        let dropNow = cue == .perfect || cue == .grace
        if dropNow {
            let pulse = reduceMotion ? 1.0 : 0.55 + 0.45 * abs(sin(clock * 9))
            context.stroke(shape, with: .color(Palette.mustard.opacity(0.5 * pulse)), lineWidth: 12)
        }
        context.fill(shape, with: .color(Palette.night.opacity(0.6)))
        var inner = context
        inner.clip(to: shape)
        if cue != .last {
            drawZones(inner, track: track, zones: zones)
        }
        drawFuel(inner, track: track, fraction: fraction, cue: cue)
        drawEmpty(inner, track: track, cue: cue, clock: clock, reduceMotion: reduceMotion)
        let outline: Color
        switch cue {
        case .perfect, .grace: outline = Palette.mustard
        case .late: outline = Palette.coral
        case .calm, .last: outline = Palette.paper.opacity(0.9)
        }
        context.stroke(shape, with: .color(outline), lineWidth: dropNow ? 3.5 : 2.5)
        if cue != .last {
            drawRuler(context, track: track, zones: zones)
        }
    }

    /// The zones as full-width bands; the fuel column is narrower, so they stay visible along its edges.
    static func drawZones(_ ctx: GraphicsContext, track: CGRect, zones: (perfect: Double, great: Double, good: Double)) {
        let bands: [(Double, Color)] = [
            (zones.good, Palette.paper.opacity(0.3)),
            (zones.great, Palette.skyTeal.opacity(0.75)),
            (zones.perfect, Palette.mustard),
        ]
        for (top, color) in bands {
            let h = track.height * CGFloat(top)
            ctx.fill(Path(CGRect(x: track.minX, y: track.maxY - h, width: track.width, height: h)), with: .color(color))
        }
    }

    static func drawFuel(_ ctx: GraphicsContext, track: CGRect, fraction: Double, cue: GaugeCue) {
        let level = track.height * CGFloat(min(1, max(0, fraction)))
        guard level > 0.5 else { return }
        let column = CGRect(x: track.minX + 6, y: track.maxY - level, width: track.width - 12, height: level)
        let color = cue == .perfect ? Palette.mustard : Palette.fuel
        let shine = cue == .perfect ? Palette.paper : Palette.mustard
        ctx.fill(Path(roundedRect: column, cornerRadius: 5), with: .linearGradient(
            Gradient(colors: [shine, color]),
            startPoint: CGPoint(x: 0, y: column.minY), endPoint: CGPoint(x: 0, y: column.minY + 14)))
        var edge = Path()
        edge.move(to: CGPoint(x: track.minX, y: column.minY))
        edge.addLine(to: CGPoint(x: track.maxX, y: column.minY))
        ctx.stroke(edge, with: .color(Palette.paper), lineWidth: 2.5)
    }

    /// Burnt out but still attached: blinks mustard and coral while a drop is still Perfect, then coral (steady with
    /// Reduce Motion).
    static func drawEmpty(_ ctx: GraphicsContext, track: CGRect, cue: GaugeCue, clock: Double, reduceMotion: Bool) {
        guard cue == .grace || cue == .late else { return }
        let on = sin(clock * 14) > 0
        let color: Color
        if cue == .grace {
            color = (reduceMotion || on) ? Palette.mustard : Palette.coral
        } else {
            color = Palette.coral
        }
        let alpha = reduceMotion ? 0.6 : (on ? 0.75 : 0.3)
        ctx.fill(Path(track), with: .color(color.opacity(alpha)))
    }

    /// A ruler right of the tank: one coloured bar per zone and a tick at each zone's top.
    static func drawRuler(_ ctx: GraphicsContext, track: CGRect, zones: (perfect: Double, great: Double, good: Double)) {
        let x = track.maxX + 4
        let marks: [(low: Double, high: Double, color: Color)] = [
            (0, zones.perfect, Palette.mustard),
            (zones.perfect, zones.great, Palette.skyTeal),
            (zones.great, zones.good, Palette.paper),
        ]
        for mark in marks {
            let top = track.maxY - track.height * CGFloat(mark.high)
            let bottom = track.maxY - track.height * CGFloat(mark.low)
            let bar = CGRect(x: x, y: top + 1, width: 4, height: max(1, bottom - top - 2))
            ctx.fill(Path(roundedRect: bar, cornerRadius: 2), with: .color(mark.color))
            var tick = Path()
            tick.move(to: CGPoint(x: track.maxX - 4, y: top))
            tick.addLine(to: CGPoint(x: x + 8, y: top))
            ctx.stroke(tick, with: .color(mark.color), lineWidth: 2)
        }
    }
}

/// The release button: a circle of 92 pt with a satellite and the number left, inside a 128 pt square that catches near
/// misses (also while it is disabled), so a slightly missed tap never drops a stage. It fires on touch-down. Inside a
/// ring band its rim turns mustard and it pulses; while a release would be Perfect the rim is gold.
struct ReleaseButton: View {
    let count: Int
    let enabled: Bool
    let band: BandCue
    let scale: CGFloat
    let driver: FlightDriver

    var body: some View {
        let rim = rimColor
        let rimWidth: CGFloat = band == .outside ? 3 : (band == .perfect ? 8 : 5)
        let glow = band == .outside ? 0 : (band == .perfect ? 0.55 : 0.35)
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle().fill(rim.opacity(glow)).padding(-12)
                Circle().fill(Palette.deepTeal)
                Circle().stroke(rim, lineWidth: rimWidth)
                SatelliteIcon(size: 50)
            }
            .frame(width: 92, height: 92)
            .shadow(color: Palette.ink.opacity(0.35), radius: 0, x: 0, y: 4)
            Text(verbatim: "\(count)")
                .font(.rounded(17, .black).monospacedDigit())
                .foregroundStyle(Palette.paper)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Palette.coral))
                .overlay(Circle().stroke(Palette.paper, lineWidth: 2))
                .offset(x: 4, y: -4)
        }
        .scaleEffect(scale)
        .opacity(enabled ? 1 : 0.5)
        .frame(width: 128, height: 128)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 10_000, perform: {}, onPressingChanged: { pressing in
            if pressing { driver.tapRelease() }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("Release satellite"))
        .accessibilityValue(Text("\(count) left"))
        .accessibilityAction { driver.tapRelease() }
        .accessibilityIdentifier("flight-release")
    }

    private var rimColor: Color {
        switch band {
        case .outside: return Palette.paper
        case .inside: return Palette.mustard
        case .perfect: return Palette.gold
        }
    }
}

struct PauseCard: View {
    let onResume: () -> Void
    let onAbort: () -> Void

    var body: some View {
        ZStack {
            Palette.night.opacity(0.55)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Paused")
                    .font(.rounded(32, .black))
                    .foregroundStyle(Palette.ink)
                    .accessibilityIdentifier("pause-title")
                Button {
                    Feedback.shared.play(.button)
                    onResume()
                } label: {
                    Text("Resume")
                }
                .buttonStyle(PillButtonStyle(fill: Palette.deepTeal))
                .accessibilityIdentifier("pause-resume")
                Button {
                    Feedback.shared.play(.button)
                    onAbort()
                } label: {
                    Text("Abort flight")
                        .font(.rounded(19, .bold))
                        .foregroundStyle(Palette.coral)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .accessibilityIdentifier("pause-abort")
                Text("An aborted flight pays nothing.")
                    .font(.rounded(14, .medium))
                    .foregroundStyle(Palette.ink.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 28).fill(Palette.cream))
            .padding(.horizontal, 32)
        }
    }
}
